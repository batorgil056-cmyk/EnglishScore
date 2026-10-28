import 'package:englishscore_intro/core_test/animated_results.dart';
import 'package:englishscore_intro/core_test/question_data.dart';
import 'package:englishscore_intro/core_test/test_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CoreTestSummary summaryWith(int correct) => CoreTestSummary(List.generate(
    55,
    (i) => CoreAnswer(
        questionId: coreQuestions[i].id,
        correct: i < correct,
        expired: false,
        choice: 0)));

void main() {
  Future<void> show(WidgetTester tester, CoreTestSummary summary,
      {Size size = const Size(375, 812),
      bool reducedMotion = false,
      ValueNotifier<bool>? saved,
      ValueNotifier<bool>? paused,
      VoidCallback? finish}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final savedState = saved ?? ValueNotifier(true);
    final pauseState = paused ?? ValueNotifier(false);
    if (saved == null) addTearDown(savedState.dispose);
    if (paused == null) addTearDown(pauseState.dispose);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: MediaQueryData.fromView(tester.view)
                .copyWith(disableAnimations: reducedMotion),
            child: Scaffold(
                backgroundColor: Colors.white,
                body: ValueListenableBuilder<bool>(
                    valueListenable: savedState,
                    builder: (context, isSaved, child) =>
                        ValueListenableBuilder<bool>(
                            valueListenable: pauseState,
                            builder: (context, isPaused, child) =>
                                AnimatedCoreResults(
                                    summary: summary,
                                    saving: false,
                                    saved: isSaved,
                                    paused: isPaused,
                                    onRetry: () {},
                                    onClose: () {},
                                    onGetCertificate: finish ?? () {})))))));
    await tester.pump();
  }

  int score(WidgetTester tester) => int.parse(tester
      .widget<Text>(find.byKey(const ValueKey('animated-result-score')))
      .data!);
  double opacity(WidgetTester tester, String key) => tester
      .widget<Opacity>(find
          .ancestor(
              of: find.byKey(ValueKey(key)), matching: find.byType(Opacity))
          .first)
      .opacity;
  double progress(WidgetTester tester, int index) => tester
      .widget<LinearProgressIndicator>(
          find.byKey(ValueKey('result-progress-$index')))
      .value!;

  testWidgets(
      'shield, actual score, progress, labels and certificate panel reveal in sequence',
      (tester) async {
    final summary = summaryWith(55);
    await show(tester, summary);
    expect(score(tester), 0);
    expect(opacity(tester, 'achievement-label'), 0);
    expect(opacity(tester, 'certificate-information-panel'), 0);
    expect(progress(tester, 0), 0);
    await tester.pump(const Duration(seconds: 1));
    expect(score(tester), greaterThan(0));
    expect(score(tester), lessThan(summary.score));
    expect(opacity(tester, 'achievement-label'), 0);
    expect(opacity(tester, 'certificate-information-panel'), 0);
    await tester.pump(const Duration(milliseconds: 2500));
    expect(score(tester), summary.score);
    expect(progress(tester, 0), 1);
    expect(progress(tester, 3), lessThan(1));
    expect(opacity(tester, 'achievement-label'), 0);
    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(tester, 'achievement-label'), greaterThan(0));
    expect(opacity(tester, 'certificate-information-panel'), 0);
    await tester.pumpAndSettle();
    expect(score(tester), 600);
    expect(progress(tester, 3), 1);
    expect(find.text('CEFR C2 · Proficient'), findsOneWidget);
    expect(opacity(tester, 'achievement-label'), 1);
    expect(opacity(tester, 'certificate-information-panel'), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final (correct, level) in [
    (0, 'A1'),
    (14, 'A2'),
    (30, 'B1'),
    (55, 'C2')
  ]) {
    testWidgets(
        'animation settles at real $level result for $correct correct answers',
        (tester) async {
      final summary = summaryWith(correct);
      await show(tester, summary, size: const Size(320, 568));
      await tester.pumpAndSettle();
      expect(score(tester), summary.score);
      expect(find.text('CEFR $level · ${summary.levelName}'), findsOneWidget);
      final fill =
          List.generate(4, (i) => progress(tester, i)).reduce((a, b) => a + b) /
              4;
      expect(fill, closeTo(summary.score / 600, .00001));
      await tester.ensureVisible(find.text('Get my certificate'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<ElevatedButton>(
                  find.widgetWithText(ElevatedButton, 'Get my certificate'))
              .onPressed,
          isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'saving rebuild does not replay animation and completion action fires once',
      (tester) async {
    final saved = ValueNotifier(false);
    addTearDown(saved.dispose);
    var finishes = 0;
    final summary = summaryWith(30);
    await show(tester, summary, saved: saved, finish: () => finishes++);
    await tester.pumpAndSettle();
    final button = find.widgetWithText(ElevatedButton, 'Get my certificate');
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    saved.value = true;
    await tester.pump();
    expect(score(tester), summary.score);
    expect(opacity(tester, 'certificate-information-panel'), 1);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(finishes, 1);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'exit/background pause resumes instead of replaying, and disposal stops the ticker',
      (tester) async {
    final paused = ValueNotifier(false);
    addTearDown(paused.dispose);
    await show(tester, summaryWith(55), paused: paused);
    await tester.pump(const Duration(seconds: 1));
    final value = score(tester);
    paused.value = true;
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(score(tester), value);
    paused.value = false;
    await tester.pump();
    await tester.pumpAndSettle();
    expect(score(tester), 600);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows final result without a count-up',
      (tester) async {
    final summary = summaryWith(14);
    await show(tester, summary, reducedMotion: true);
    expect(score(tester), summary.score);
    expect(opacity(tester, 'certificate-information-panel'), 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
