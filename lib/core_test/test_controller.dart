import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../test_results.dart';
import 'question_data.dart';

enum CoreTestPhase { introduction, question, complete }

class CoreAnswer {
  const CoreAnswer(
      {required this.questionId,
      required this.correct,
      required this.expired,
      this.choice,
      this.order});
  final String questionId;
  final int? choice;
  final List<int>? order;
  final bool correct;
  final bool expired;
  bool get answered => choice != null || order != null;
}

/// Answer statistics remain available, but a completed attempt uses its frozen,
/// randomly generated demo result, independently of answer correctness.
class CoreTestSummary {
  CoreTestSummary(List<CoreAnswer> answers,
      {this.reportId, this.completedAt, this.generatedResult})
      : answers = List.unmodifiable(answers);
  final DemoResult? generatedResult;
  final String? reportId;
  final DateTime? completedAt;
  final List<CoreAnswer> answers;
  int get correct => answers.where((a) => a.correct).length;
  int get answered => answers.where((a) => a.answered).length;
  int get score =>
      generatedResult?.score ??
      averageCoreSkills(CoreSkill.values.map(skillScore).toList());
  String get cefr => coreCefrForScore(score);
  String get levelName => cefrDescription(cefr);
  int skillScore(CoreSkill skill) {
    final generated = generatedResult;
    if (generated != null) {
      return switch (skill) {
        CoreSkill.grammar => generated.grammar!,
        CoreSkill.reading => generated.reading!,
        CoreSkill.vocabulary => generated.vocabulary!,
        CoreSkill.listening => generated.listening!,
      };
    }
    final questions = coreQuestions.where((q) => q.skill == skill).toList();
    final correct = answers
        .where((a) => a.correct && questions.any((q) => q.id == a.questionId))
        .length;
    return (correct / questions.length * 600).round();
  }

  DemoResult get result =>
      generatedResult ??
      DemoResult(score, cefr,
          id: reportId,
          completedAt: completedAt,
          grammar: skillScore(CoreSkill.grammar),
          vocabulary: skillScore(CoreSkill.vocabulary),
          reading: skillScore(CoreSkill.reading),
          listening: skillScore(CoreSkill.listening));
  int correctIn(CorePart part) => answers
      .where((a) =>
          a.correct &&
          coreQuestions.any((q) => q.id == a.questionId && q.part == part))
      .length;
}

class CoreTestController extends ChangeNotifier {
  CoreTestController({bool autoTick = true, math.Random? random})
      : _random = random {
    if (autoTick) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }
  final math.Random? _random;
  DemoResult? _generatedResult;
  Timer? _timer;
  final String _attemptId =
      '${DateTime.now().toUtc().microsecondsSinceEpoch}-${math.Random.secure().nextInt(0x100000000).toRadixString(16)}';
  DateTime? _completedAt;
  bool _disposed = false;
  bool _paused = false;
  int _index = 0;
  int _seconds = 30;
  int? _selected;
  List<int> _order = [];
  bool _orderTouched = false;
  CoreTestPhase _phase = CoreTestPhase.introduction;
  final List<CoreAnswer> _answers = [];

  CoreTestPhase get phase => _phase;
  CoreQuestion get question => coreQuestions[_index];
  CorePart get part => question.part;
  int get index => _index;
  int get seconds => _seconds;
  int? get selected => _selected;
  List<int> get order => List.unmodifiable(_order);
  List<CoreAnswer> get answers => List.unmodifiable(_answers);
  int get questionInPart =>
      coreQuestions.take(_index).where((q) => q.part == part).length + 1;
  int get partTotal => coreQuestions.where((q) => q.part == part).length;
  bool get paused => _paused;
  bool get canSubmit =>
      !_paused &&
      _phase == CoreTestPhase.question &&
      (question.kind == QuestionKind.ordering || _selected != null);
  CoreTestSummary get summary => CoreTestSummary(_answers,
      reportId: _attemptId,
      completedAt: _completedAt,
      generatedResult: _generatedResult);

  void setPaused(bool value) {
    if (_disposed || _paused == value) return;
    _paused = value;
    notifyListeners();
  }

  void startPart() {
    if (_disposed || _paused || _phase != CoreTestPhase.introduction) return;
    _phase = CoreTestPhase.question;
    _resetQuestion();
    notifyListeners();
  }

  void _resetQuestion() {
    _seconds = part.questionSeconds;
    _selected = null;
    _order = question.initialOrder;
    _orderTouched = false;
  }

  void select(int choice) {
    if (_disposed ||
        _paused ||
        _phase != CoreTestPhase.question ||
        question.kind == QuestionKind.ordering ||
        choice < 0 ||
        choice >= question.choices.length) {
      return;
    }
    _selected = choice;
    notifyListeners();
  }

  /// Indices include the locked opening sentence, so it cannot be moved.
  void reorder(int oldIndex, int newIndex) {
    if (_disposed ||
        _paused ||
        _phase != CoreTestPhase.question ||
        question.kind != QuestionKind.ordering ||
        oldIndex <= 0 ||
        oldIndex >= _order.length ||
        newIndex <= 0 ||
        newIndex >= _order.length) {
      return;
    }
    final item = _order.removeAt(oldIndex);
    _order.insert(newIndex, item);
    _orderTouched = true;
    notifyListeners();
  }

  void tick() {
    if (_disposed || _paused || _phase == CoreTestPhase.complete) return;
    if (_seconds > 1) {
      _seconds--;
      notifyListeners();
    } else if (_phase == CoreTestPhase.introduction) {
      startPart();
    } else {
      submit(expired: true);
    }
  }

  void skipUnanswered() {
    if (question.kind != QuestionKind.listening) return;
    _selected = null;
    submit(skipped: true);
  }

  void submit({bool expired = false, bool skipped = false}) {
    if (_disposed ||
        _paused ||
        _phase != CoreTestPhase.question ||
        (!expired && !skipped && !canSubmit)) {
      return;
    }
    final ordering = question.kind == QuestionKind.ordering;
    final submittedOrder = ordering && (!expired || _orderTouched)
        ? List<int>.unmodifiable(_order)
        : null;
    final correct = ordering
        ? submittedOrder != null &&
            listEquals(submittedOrder,
                List.generate(question.sentences.length, (i) => i))
        : _selected != null && _selected == question.correctChoice;
    _answers.add(CoreAnswer(
        questionId: question.id,
        choice: _selected,
        order: submittedOrder,
        correct: correct,
        expired: expired));
    if (_index == coreQuestions.length - 1) {
      _completedAt = DateTime.now().toUtc();
      _generatedResult = _generateDemoResult();
      _phase = CoreTestPhase.complete;
      _timer?.cancel();
    } else {
      final previousPart = part;
      _index++;
      _resetQuestion();
      if (part != previousPart) {
        _phase = CoreTestPhase.introduction;
        _seconds = 30;
      }
    }
    notifyListeners();
  }

  DemoResult _generateDemoResult() {
    final random = _random ?? math.Random();
    final score = 400 + random.nextInt(51);
    // Balanced offsets keep the sum exactly 4 * score. Every section is
    // between 350 and 500, safely within 0–600, independent of the answers.
    final firstOffset = random.nextInt(101) - 50;
    final secondOffset = random.nextInt(101) - 50;
    final sections = [
      score + firstOffset,
      score - firstOffset,
      score + secondOffset,
      score - secondOffset
    ]..shuffle(random);
    return DemoResult(score, coreCefrForScore(score),
        id: _attemptId,
        completedAt: _completedAt,
        grammar: sections[0],
        reading: sections[1],
        vocabulary: sections[2],
        listening: sections[3]);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
