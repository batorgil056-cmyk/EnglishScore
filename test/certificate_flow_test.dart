import 'package:englishscore_intro/core_test/certificate_selection.dart';
import 'package:englishscore_intro/core_test/question_data.dart';
import 'package:englishscore_intro/core_test/test_controller.dart';
import 'package:englishscore_intro/core_test/test_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/test_speech_backend.dart';

CoreTestController _lastQuestion() {
  final test = CoreTestController(autoTick: false);
  while (test.index < 54) {
    if (test.phase == CoreTestPhase.introduction) test.startPart();
    if (test.question.kind == QuestionKind.ordering) {
      test.reorder(3, 1);
    } else {
      test.select(test.question.correctChoice!);
    }
    test.submit();
  }
  return test;
}

void main() {
  Future<void> configure(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  for (final size in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(430, 932)
  ]) {
    testWidgets(
        'both certificate tabs, real result preview and demo Buy at $size',
        (tester) async {
      await configure(tester, size);
      final test = _lastQuestion();
      addTearDown(test.dispose);
      test.select(test.question.correctChoice!);
      test.submit();
      var laters = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: CoreCertificateSelection(
                  summary: test.summary,
                  saving: false,
                  finishing: false,
                  onRetry: () {},
                  onLater: () => laters++))));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('certificate-preview-score')))
              .data,
          test.summary.score.toString());
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('certificate-preview-level')))
              .data,
          'CEFR B2');
      expect(find.text(r'USD $24.99'), findsOneWidget);
      await tap(tester, 'Buy');
      expect(find.text('Demo certificate preview'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tap(tester, 'OK');
      await tap(tester, "I don't need a certificate");
      expect(find.byKey(const ValueKey('certificate-later-illustration')),
          findsOneWidget);
      expect(find.text('Not yet ready to buy a certificate?'), findsOneWidget);
      expect(find.text(r'USD $24.99'), findsNothing);
      await tap(tester, r'$24.99');
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('certificate-preview-score')))
              .data,
          test.summary.score.toString());
      await tap(tester, "I don't need a certificate");
      await tap(tester, 'Later');
      expect(laters, 1);
      expect(test.summary.score, inInclusiveRange(400, 450));
      expect(test.answers.length, 55);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'last Listening question opens result, certificate picker and saves again on Later before finishing',
      (tester) async {
    await configure(tester, const Size(375, 812));
    final test = _lastQuestion();
    addTearDown(test.dispose);
    var saves = 0, finishes = 0;
    await tester.pumpWidget(MaterialApp(
        home: CoreSkillsTestScreen(
            paused: false,
            onClose: () {},
            onFinish: () => finishes++,
            controller: test,
            speechBackend: TestSpeechBackend()..instant = true,
            saveResult: (result) async {
              expect(result.score, inInclusiveRange(400, 450));
              expect(result.cefr, 'B2');
              saves++;
            })));
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('Play listening audio'));
    await tester.tap(find.byTooltip('Play listening audio'));
    await tester.pump();
    await tap(
        tester,
        listeningQuestions
            .last.choices[listeningQuestions.last.correctChoice!]);
    await tap(tester, 'NEXT');
    expect(find.text('Well done!'), findsOneWidget);
    expect(
        find.text("You've unlocked the B2 level certificate"), findsOneWidget);
    expect(saves, 1);
    expect(finishes, 0);
    await tap(tester, 'Get my certificate');
    expect(find.text('Pick your certificate'), findsOneWidget);
    expect(finishes, 0);
    await tap(tester, "I don't need a certificate");
    await tap(tester, 'Later');
    expect(saves, 2);
    expect(finishes, 1);
    expect(test.summary.score, inInclusiveRange(400, 450));
    expect(test.answers.length, 55);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Later'))
            .onPressed,
        isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Later save failure stays on the selected tab and can retry without losing the score',
      (tester) async {
    await configure(tester, const Size(320, 568));
    final test = _lastQuestion();
    addTearDown(test.dispose);
    test.select(test.question.correctChoice!);
    test.submit();
    var saves = 0, finishes = 0;
    await tester.pumpWidget(MaterialApp(
        home: CoreSkillsTestScreen(
            paused: false,
            onClose: () {},
            onFinish: () => finishes++,
            controller: test,
            speechBackend: TestSpeechBackend(),
            saveResult: (result) async {
              expect(result.score, inInclusiveRange(400, 450));
              if (++saves == 2) throw StateError('Storage unavailable');
            })));
    await tester.pumpAndSettle();
    await tap(tester, 'Get my certificate');
    await tap(tester, "I don't need a certificate");
    await tap(tester, 'Later');
    expect(finishes, 0);
    expect(find.text('Retry saving'), findsOneWidget);
    expect(find.byKey(const ValueKey('certificate-later-illustration')),
        findsOneWidget);
    await tap(tester, 'Retry saving');
    await tap(tester, 'Later');
    expect(saves, 4);
    expect(finishes, 1);
    expect(test.summary.score, inInclusiveRange(400, 450));
    await tester.pumpWidget(const SizedBox());
  });
}
