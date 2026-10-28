import 'package:englishscore_intro/core_test/question_data.dart';
import 'package:englishscore_intro/core_test/test_controller.dart';
import 'package:englishscore_intro/test_results.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('question bank is exactly 30/15/10 original, valid and complete', () {
    expect(coreQuestions.length, 55);
    expect(grammarQuestions.length, 30);
    expect(readingQuestions.length, 15);
    expect(listeningQuestions.length, 10);
    expect(coreQuestions.map((q) => q.id).toSet().length, 55);
    expect(coreQuestions.map((q) => q.prompt).toSet().length,
        51); // Five ordering questions share instructions.
    expect(
        grammarQuestions.map((q) => q.level).toSet(), {'A1', 'A2', 'B1', 'B2'});
    for (final q in coreQuestions) {
      expect(q.heading, isNotEmpty);
      expect(q.prompt, isNotEmpty);
      if (q.kind == QuestionKind.ordering) {
        expect(q.sentences.length, 4);
        expect(q.sentences.toSet().length, 4);
        expect(q.initialOrder.toSet(), {0, 1, 2, 3});
        expect(q.initialOrder.first, 0);
      } else {
        expect(q.choices.length, 3);
        expect(q.choices.toSet().length, 3);
        expect(q.correctChoice, inInclusiveRange(0, 2));
      }
      if (q.part == CorePart.listening) {
        expect(q.kind, QuestionKind.listening);
        expect(q.script!.split(' ').length, greaterThan(25));
      }
      if (q.part == CorePart.reading && q.kind != QuestionKind.ordering) {
        expect(q.passage, isNotEmpty);
      }
    }
  });

  test(
      'all 55 answers, three transitions, correct scoring and no duplicate completion',
      () {
    final test = CoreTestController(autoTick: false);
    addTearDown(test.dispose);
    final introductions = <CorePart>[];
    while (test.phase != CoreTestPhase.complete) {
      if (test.phase == CoreTestPhase.introduction) {
        introductions.add(test.part);
        expect(test.seconds, 30);
        test.startPart();
      }
      if (test.question.kind == QuestionKind.ordering) {
        expect(test.order, [0, 2, 3, 1]);
        test.reorder(3, 1);
        expect(test.order, [0, 1, 2, 3]);
      } else {
        test.select(test.question.correctChoice!);
      }
      test.submit();
    }
    expect(introductions, CorePart.values);
    expect(test.answers.length, 55);
    expect(test.summary.correct, 55);
    expect(test.summary.answered, 55);
    expect(test.summary.score, inInclusiveRange(400, 450));
    expect(test.summary.cefr, 'B2');
    expect(test.summary.correctIn(CorePart.reading), 15);
    test.submit();
    test.tick();
    test.startPart();
    expect(test.answers.length, 55);
  });

  test(
      'expiry records all 55 unanswered while completion uses demo-only random scoring',
      () {
    final test = CoreTestController(autoTick: false);
    addTearDown(test.dispose);
    while (test.phase != CoreTestPhase.complete) {
      test.tick();
    }
    expect(test.answers.length, 55);
    expect(test.answers.every((a) => a.expired), isTrue);
    expect(test.summary.answered, 0);
    expect(test.summary.correct, 0);
    expect(test.summary.score, inInclusiveRange(400, 450));
    expect(test.summary.cefr, 'B2');
  });

  test(
      'pause blocks countdowns, start, selection and submission; expiry keeps a selected answer',
      () {
    final test = CoreTestController(autoTick: false);
    addTearDown(test.dispose);
    test.setPaused(true);
    test.startPart();
    test.tick();
    expect(test.phase, CoreTestPhase.introduction);
    expect(test.seconds, 30);
    test.setPaused(false);
    test.startPart();
    test.select(1);
    test.setPaused(true);
    test.tick();
    test.select(0);
    test.submit();
    expect(test.index, 0);
    expect(test.seconds, 42);
    expect(test.selected, 1);
    test.setPaused(false);
    for (var i = 0; i < 42; i++) {
      test.tick();
    }
    expect(test.answers.single.correct, isTrue);
    expect(test.answers.single.expired, isTrue);
    expect(test.selected, isNull);
    expect(test.canSubmit, isFalse);
  });

  test('locked sentence cannot move and wrong order never gets credit', () {
    final test = CoreTestController(autoTick: false);
    addTearDown(test.dispose);
    test.startPart();
    for (var i = 0; i < 30; i++) {
      test.submit(expired: true);
    }
    expect(test.part, CorePart.reading);
    test.startPart();
    test.reorder(0, 3);
    test.reorder(1, 0);
    expect(test.order, [0, 2, 3, 1]);
    test.submit();
    expect(test.answers.last.correct, isFalse);
    expect(test.answers.last.answered, isTrue);
    expect(test.summary.correct, 0);
  });

  test('existing CEFR boundaries extend consistently to C1 and C2', () {
    for (final (score, level) in [
      (0, 'A1'),
      (124, 'A1'),
      (125, 'A2'),
      (249, 'A2'),
      (250, 'B1'),
      (374, 'B1'),
      (375, 'B2'),
      (499, 'B2'),
      (500, 'C1'),
      (599, 'C1'),
      (600, 'C2')
    ]) {
      expect(coreCefrForScore(score), level);
    }
    expect(averageCoreSkills([120, 140, 160, 180]), 150);
    expect(() => averageCoreSkills([120, 140, 160]), throwsArgumentError);
    expect(() => averageCoreSkills([120, 140, 160, 601]), throwsArgumentError);
  });

  test(
      'overall is rounded mean of all four independently calculated skill scores',
      () {
    for (var correct = 0; correct <= 55; correct++) {
      final answers = List.generate(
          55,
          (i) => CoreAnswer(
              questionId: coreQuestions[i].id,
              correct: i < correct,
              expired: false,
              choice: 0));
      final summary = CoreTestSummary(answers);
      final skills = CoreSkill.values.map(summary.skillScore).toList();
      expect(skills.every((value) => value >= 0 && value <= 600), isTrue);
      expect(summary.score, (skills.reduce((a, b) => a + b) / 4).round());
      expect(summary.result.score, summary.score);
      expect(summary.result.cefr, summary.cefr);
    }
  });

  test(
      'saving a completed core result survives reload and preserves other results',
      () async {
    SharedPreferences.setMockInitialValues({});
    await DemoResults.preview(2).save();
    await DemoResults.saveCore(const DemoResult(327, 'B1'));
    final saved = await DemoResults.load();
    expect(saved.results['core']!.score, 327);
    expect(saved.results['core']!.cefr, 'B1');
    expect(saved.results['speaking']!.score, 360);
    expect(saved.results['writing']!.score, 430);
  });
}
