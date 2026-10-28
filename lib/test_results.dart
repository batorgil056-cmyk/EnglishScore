import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Retain the existing A1–B2 demo thresholds and extend the scale to 600.
String coreCefrForScore(int score) {
  if (score < 0 || score > 600) throw RangeError.range(score, 0, 600, 'score');
  return score < 125
      ? 'A1'
      : score < 250
          ? 'A2'
          : score < 375
              ? 'B1'
              : score < 500
                  ? 'B2'
                  : score < 600
                      ? 'C1'
                      : 'C2';
}

int averageCoreSkills(List<int> scores) {
  if (scores.length != 4 || scores.any((score) => score < 0 || score > 600)) {
    throw ArgumentError('Four section scores between 0 and 600 are required.');
  }
  return (scores.reduce((a, b) => a + b) / 4).round();
}

String cefrDescription(String cefr) => switch (cefr) {
      'A1' => 'Beginner',
      'A2' => 'Elementary',
      'B1' => 'Intermediate',
      'B2' => 'Upper Intermediate',
      'C1' => 'Advanced',
      'C2' => 'Proficient',
      _ => 'Pre-beginner',
    };

String formatTestDate(DateTime? timestamp) {
  if (timestamp == null) return 'Date unavailable';
  final local = timestamp.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} ${local.year}';
}

/// Local demo scores only, never official EnglishScore results. Older preview
/// data has no date or breakdown; absent historical values stay absent.
class DemoResult {
  const DemoResult(int score, String cefr,
      {this.id,
      this.completedAt,
      this.grammar,
      this.vocabulary,
      this.reading,
      this.listening})
      : _storedScore = score,
        _storedCefr = cefr;
  final int _storedScore;
  final String _storedCefr;
  bool get hasSectionScores => [grammar, vocabulary, reading, listening]
      .every((value) => value != null && value >= 0 && value <= 600);
  int get score => hasSectionScores
      ? averageCoreSkills([grammar!, reading!, vocabulary!, listening!])
      : _storedScore;
  String get cefr => hasSectionScores ? coreCefrForScore(score) : _storedCefr;
  final String? id;
  final DateTime? completedAt;
  final int? grammar, vocabulary, reading, listening;
  String get levelName => cefrDescription(cefr);
  bool get isReport => id != null && completedAt != null;
  Map<String, Object> toJson() => {
        'score': score,
        'cefr': cefr,
        if (id != null) 'id': id!,
        if (completedAt != null)
          'completedAt': completedAt!.toUtc().toIso8601String(),
        if (grammar != null) 'grammar': grammar!,
        if (vocabulary != null) 'vocabulary': vocabulary!,
        if (reading != null) 'reading': reading!,
        if (listening != null) 'listening': listening!,
      };
  static DemoResult? fromJson(dynamic value) {
    if (value is! Map ||
        value['score'] is! int ||
        value['score'] < 0 ||
        value['score'] > 600 ||
        !['Pre A1', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2']
            .contains(value['cefr'])) {
      return null;
    }
    int? skill(String key) {
      final score = value[key];
      return score is int && score >= 0 && score <= 600 ? score : null;
    }

    return DemoResult(value['score'] as int, value['cefr'] as String,
        id: value['id'] is String && (value['id'] as String).isNotEmpty
            ? value['id'] as String
            : null,
        completedAt: value['completedAt'] is String
            ? DateTime.tryParse(value['completedAt'] as String)?.toUtc()
            : null,
        grammar: skill('grammar'),
        vocabulary: skill('vocabulary'),
        reading: skill('reading'),
        listening: skill('listening'));
  }
}

class DemoResults {
  DemoResults(this.results,
      {List<DemoResult> coreReports = const [], this.legacyCore})
      : coreReports = List.unmodifiable(coreReports);
  final Map<String, DemoResult> results;
  final List<DemoResult> coreReports;
  final DemoResult? legacyCore;
  static const storageKey = 'englishscore.demo.results.v1';
  static Future<void>? _writes;

  static DemoResults preview(int state) => DemoResults({
        if (state >= 1) 'core': const DemoResult(410, 'B2'),
        if (state >= 2) 'speaking': const DemoResult(360, 'B1'),
        if (state >= 2) 'writing': const DemoResult(430, 'B2'),
      });

  /// Serialize writes and upsert an attempt by its stable ID: completion, Retry
  /// and Later save the same report. A real retake gets a separate ID.
  static Future<void> saveCore(DemoResult result) {
    Future<void> persist() async {
      if ((result.id != null || result.completedAt != null) &&
          !result.hasSectionScores) {
        throw StateError(
            'Cannot save a completed Core Skills result without all four section scores.');
      }
      final existing = await load();
      final reports = [...existing.coreReports];
      if (result.isReport) {
        reports.removeWhere((r) => r.id == result.id);
        reports.add(result);
        _sort(reports);
      }
      await DemoResults({
        ...existing.results,
        'core': result.isReport ? reports.first : result
      },
              coreReports: reports,
              legacyCore: existing.legacyCore ??
                  (result.isReport &&
                          existing.results['core']?.isReport == false
                      ? existing.results['core']
                      : null))
          .save();
    }

    final previous = _writes;
    final write = previous == null
        ? persist()
        : previous.then((_) => persist(),
            onError: (Object error, StackTrace stack) => persist());
    _writes = write;
    write.then<void>((_) {
      if (identical(_writes, write)) _writes = null;
    }, onError: (Object error, StackTrace stack) {
      if (identical(_writes, write)) _writes = null;
    });
    return write;
  }

  static void _sort(List<DemoResult> reports) => reports.sort((a, b) {
        final date = b.completedAt!.compareTo(a.completedAt!);
        return date != 0 ? date : b.id!.compareTo(a.id!);
      });
  DemoResult? get bestCore {
    final candidates = [...coreReports, if (legacyCore != null) legacyCore!];
    if (candidates.isEmpty) return results['core'];
    return candidates.reduce((a, b) => b.score > a.score ? b : a);
  }

  static Future<DemoResults> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return preview(0);
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final results = <String, DemoResult>{};
      for (final name in ['core', 'speaking', 'writing']) {
        final result = DemoResult.fromJson(json[name]);
        if (result != null) results[name] = result;
      }
      final reports = <String, DemoResult>{};
      if (json['_coreReports'] is List) {
        for (final entry in json['_coreReports'] as List) {
          final result = DemoResult.fromJson(entry);
          if (result != null && result.isReport) reports[result.id!] = result;
        }
      }
      final dated = reports.values.toList();
      _sort(dated);
      if (dated.isNotEmpty) results['core'] = dated.first;
      return DemoResults(results.containsKey('core') ? results : {},
          coreReports: dated,
          legacyCore: DemoResult.fromJson(json['_legacyCore']));
    } on FormatException {
      return preview(0);
    } on TypeError {
      return preview(0);
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, Object>{
      ...results.map((key, value) => MapEntry(key, value.toJson())),
      if (coreReports.isNotEmpty)
        '_coreReports': coreReports.map((r) => r.toJson()).toList(),
      if (legacyCore != null) '_legacyCore': legacyCore!.toJson(),
    };
    if (!await prefs.setString(storageKey, jsonEncode(payload))) {
      throw StateError('Could not save demo results');
    }
  }
}
