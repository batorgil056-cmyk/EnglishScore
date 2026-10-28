import 'dart:convert';
import 'package:englishscore_intro/test_results.dart';
import 'package:englishscore_intro/core_test/question_data.dart';
import 'package:englishscore_intro/core_test/test_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DemoResult datedResult(String id, int score, DateTime date,
        {String cefr = 'B1'}) =>
    DemoResult(score, cefr,
        id: id,
        completedAt: date,
        grammar: score,
        vocabulary: score,
        reading: score,
        listening: score);

void main() {
  test(
      'report history persists, sorts newest first, updates same ID and selects highest score',
      () async {
    SharedPreferences.setMockInitialValues({});
    await DemoResults.preview(2).save();
    final older = datedResult('older', 410, DateTime.utc(2026, 1, 1, 12));
    final newer =
        datedResult('newer', 220, DateTime.utc(2026, 1, 2, 12), cefr: 'A2');
    await DemoResults.saveCore(older);
    await DemoResults.saveCore(newer);
    await DemoResults.saveCore(newer);
    var loaded = await DemoResults.load();
    expect(loaded.coreReports.map((r) => r.id), ['newer', 'older']);
    expect(loaded.bestCore!.id, 'older');
    expect(loaded.results['core']!.score, 220);
    expect(loaded.results['speaking']!.score, 360);
    expect(loaded.results['writing']!.score, 430);
    expect(loaded.coreReports.first.grammar, 220);
    expect(loaded.coreReports.first.vocabulary, 220);
    expect(loaded.coreReports.first.reading, 220);
    expect(loaded.coreReports.first.listening, 220);
    await DemoResults.saveCore(
        older); // Opening an older certificate must never make it newest.
    loaded = await DemoResults.load();
    expect(loaded.results['core']!.id, 'newer');
    expect(loaded.coreReports.length, 2);
    expect(loaded.coreReports.last.completedAt, DateTime.utc(2026, 1, 1, 12));
  });
  test(
      'concurrent saves do not lose reports and ties select the newest highest score',
      () async {
    SharedPreferences.setMockInitialValues({});
    await Future.wait([
      DemoResults.saveCore(datedResult('a', 300, DateTime.utc(2026, 1, 1, 12))),
      DemoResults.saveCore(datedResult('b', 300, DateTime.utc(2026, 1, 2, 12)))
    ]);
    final loaded = await DemoResults.load();
    expect(loaded.coreReports.length, 2);
    expect(loaded.bestCore!.id, 'b');
  });
  test(
      'legacy previews stay readable without inventing dates or breakdowns; malformed history is ignored',
      () async {
    SharedPreferences.setMockInitialValues({
      DemoResults.storageKey: jsonEncode({
        'core': {'score': 327, 'cefr': 'B1'},
        '_coreReports': [
          {'score': 300, 'cefr': 'B1', 'id': 'missing-date'},
          'bad'
        ],
      })
    });
    final loaded = await DemoResults.load();
    expect(loaded.results['core']!.score, 327);
    expect(loaded.coreReports, isEmpty);
    expect(loaded.results['core']!.completedAt, isNull);
    expect(loaded.results['core']!.grammar, isNull);
    expect(formatTestDate(null), 'Date unavailable');
  });
  test(
      'first dated attempt preserves an older undated summary without fabricating metadata',
      () async {
    SharedPreferences.setMockInitialValues({});
    await DemoResults({'core': const DemoResult(410, 'B2')}).save();
    await DemoResults.saveCore(datedResult(
        'new-attempt', 220, DateTime.utc(2026, 2, 3, 12),
        cefr: 'A2'));
    final loaded = await DemoResults.load();
    expect(loaded.coreReports.length, 1);
    expect(loaded.legacyCore!.score, 410);
    expect(loaded.legacyCore!.completedAt, isNull);
    expect(loaded.legacyCore!.grammar, isNull);
    expect(loaded.bestCore!.score, 410);
    expect(loaded.results['core']!.id, 'new-attempt');
  });

  test(
      'completion creates stable ID/date and correct stored skill scores; retakes get a distinct ID',
      () {
    final test = CoreTestController(autoTick: false);
    addTearDown(test.dispose);
    final before = DateTime.now().toUtc();
    while (test.phase != CoreTestPhase.complete) {
      if (test.phase == CoreTestPhase.introduction) test.startPart();
      if (test.question.skill == CoreSkill.vocabulary) {
        test.select(test.question.correctChoice!);
      }
      test.submit(expired: true);
    }
    final report = test.summary.result;
    expect(report.score, inInclusiveRange(400, 450));
    expect(report.cefr, 'B2');
    final sections = [
      report.grammar!,
      report.reading!,
      report.vocabulary!,
      report.listening!
    ];
    expect(sections.every((value) => value >= 0 && value <= 600), isTrue);
    expect(averageCoreSkills(sections), report.score);
    expect(report.isReport, isTrue);
    expect(report.completedAt!.isBefore(before), isFalse);
    expect(test.summary.result.id, report.id);
    expect(test.summary.result.completedAt, report.completedAt);
    final retake = CoreTestController(autoTick: false);
    addTearDown(retake.dispose);
    while (retake.phase != CoreTestPhase.complete) {
      retake.tick();
    }
    expect(retake.summary.result.id, isNot(report.id));
  });
  test(
      'stored four scores are preserved and overall/CEFR normalize to their arithmetic mean',
      () async {
    final date = DateTime.utc(2026, 4, 5, 12);
    final data = {
      'id': 'existing',
      'completedAt': date.toIso8601String(),
      'score': 999,
      'cefr': 'B2',
      'grammar': 120,
      'reading': 140,
      'vocabulary': 160,
      'listening': 180
    };
    data['score'] = 410;
    SharedPreferences.setMockInitialValues({
      DemoResults.storageKey: jsonEncode({
        'core': data,
        '_coreReports': [data]
      })
    });
    final result = (await DemoResults.load()).coreReports.single;
    expect(result.score, 150);
    expect(result.cefr, coreCefrForScore(150));
    expect(
        [result.grammar, result.reading, result.vocabulary, result.listening],
        [120, 140, 160, 180]);
    expect(result.id, 'existing');
    expect(result.completedAt, date);
    await DemoResults.saveCore(result);
    expect((await DemoResults.load()).coreReports.single.score, 150);
  });

  test(
      'missing section is explicit and never silently contributes zero to a mean',
      () async {
    final date = DateTime.utc(2026, 4, 5, 12);
    final incomplete = DemoResult(410, 'B2',
        id: 'incomplete',
        completedAt: date,
        grammar: 120,
        reading: 140,
        vocabulary: 160);
    expect(incomplete.hasSectionScores, isFalse);
    expect(incomplete.score, 410);
    await expectLater(DemoResults.saveCore(incomplete), throwsStateError);
    SharedPreferences.setMockInitialValues({
      DemoResults.storageKey: jsonEncode({
        'core': incomplete.toJson(),
        '_coreReports': [incomplete.toJson()]
      })
    });
    final result = (await DemoResults.load()).coreReports.single;
    expect(result.hasSectionScores, isFalse);
    expect(result.listening, isNull);
    expect(result.score, 410);
    final full = datedResult('complete', 600, date, cefr: 'C2');
    await DemoResults.saveCore(full);
    expect(
        (await DemoResults.load())
            .coreReports
            .firstWhere((r) => r.id == 'complete')
            .score,
        600);
  });
}
