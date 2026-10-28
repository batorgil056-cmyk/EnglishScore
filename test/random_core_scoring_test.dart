import 'dart:math';
import 'package:englishscore_intro/core_test/question_data.dart';
import 'package:englishscore_intro/core_test/test_controller.dart';
import 'package:englishscore_intro/test_results.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingRandom implements Random {
  _CountingRandom(this.first);
  final int first;
  int calls = 0;
  @override
  int nextInt(int max) => ++calls == 1 ? first : max ~/ 2;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => .5;
}

void _complete(CoreTestController test, {bool correct = false}) {
  while (test.phase != CoreTestPhase.complete) {
    if (test.phase == CoreTestPhase.introduction) test.startPart();
    if (correct) {
      if (test.question.kind == QuestionKind.ordering) {
        test.reorder(3, 1);
      } else {
        test.select(test.question.correctChoice!);
      }
    }
    test.submit(expired: !correct);
  }
}

void main() {
  test(
      'both inclusive score endpoints work and generation happens only once on final submission',
      () {
    for (final first in [0, 50]) {
      final random = _CountingRandom(first);
      final test = CoreTestController(autoTick: false, random: random);
      addTearDown(test.dispose);
      while (test.index < 54) {
        if (test.phase == CoreTestPhase.introduction) test.startPart();
        test.submit(expired: true);
      }
      expect(random.calls, 0);
      test.summary;
      test.summary;
      expect(random.calls, 0);
      test.submit(expired: true);
      final snapshot = test.summary.result;
      expect(snapshot.score, 400 + first);
      expect(snapshot.cefr, 'B2');
      expect(snapshot.levelName, 'Upper Intermediate');
      expect(
          averageCoreSkills([
            snapshot.grammar!,
            snapshot.reading!,
            snapshot.vocabulary!,
            snapshot.listening!
          ]),
          snapshot.score);
      final calls = random.calls;
      for (var i = 0; i < 20; i++) {
        test.tick();
        test.submit(expired: true);
        expect(test.summary.result.toJson(), snapshot.toJson());
      }
      expect(random.calls, calls);
    }
  });
  test('correctness does not influence the random total or four section scores',
      () {
    final correct = CoreTestController(autoTick: false, random: Random(42));
    final unanswered = CoreTestController(autoTick: false, random: Random(42));
    addTearDown(correct.dispose);
    addTearDown(unanswered.dispose);
    _complete(correct, correct: true);
    _complete(unanswered);
    expect(correct.summary.correct, 55);
    expect(unanswered.summary.correct, 0);
    expect(correct.summary.score, unanswered.summary.score);
    for (final skill in CoreSkill.values) {
      expect(correct.summary.skillScore(skill),
          unanswered.summary.skillScore(skill));
    }
  });
  test(
      'all generated section scores stay in range and have the exact generated mean',
      () {
    for (var seed = 0; seed < 100; seed++) {
      final test = CoreTestController(autoTick: false, random: Random(seed));
      _complete(test);
      final result = test.summary.result;
      expect(result.score, inInclusiveRange(400, 450));
      final sections = [
        result.grammar!,
        result.reading!,
        result.vocabulary!,
        result.listening!
      ];
      expect(sections.every((score) => score >= 0 && score <= 600), isTrue);
      expect(sections.reduce((a, b) => a + b), result.score * 4);
      expect(result.cefr, 'B2');
      test.dispose();
    }
  });
  test(
      'completion, Later, storage reload and retake preserve separate frozen records',
      () async {
    SharedPreferences.setMockInitialValues({});
    final first =
        CoreTestController(autoTick: false, random: _CountingRandom(0));
    final second =
        CoreTestController(autoTick: false, random: _CountingRandom(50));
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    _complete(first);
    final original = first.summary.result;
    await DemoResults.saveCore(original);
    await DemoResults.saveCore(first.summary.result);
    expect((await DemoResults.load()).coreReports.single.toJson(),
        original.toJson());
    _complete(second, correct: true);
    final retake = second.summary.result;
    await DemoResults.saveCore(retake);
    final reloaded = await DemoResults.load();
    expect(reloaded.coreReports.length, 2);
    expect(original.id, isNot(retake.id));
    expect(reloaded.coreReports.firstWhere((r) => r.id == original.id).toJson(),
        original.toJson());
    expect(reloaded.coreReports.firstWhere((r) => r.id == retake.id).toJson(),
        retake.toJson());
    expect(original.score, 400);
    expect(retake.score, 450);
  });
}
