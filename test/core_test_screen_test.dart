import 'package:englishscore_intro/core_test/question_data.dart';
import 'package:englishscore_intro/core_test/test_controller.dart';
import 'package:englishscore_intro/core_test/test_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/test_speech_backend.dart';

CoreTestController atQuestion(int index) {
  final test = CoreTestController(autoTick: false);
  while (test.index < index) {
    if (test.phase == CoreTestPhase.introduction) test.startPart();
    test.submit(expired: true);
  }
  if (test.phase == CoreTestPhase.introduction) test.startPart();
  return test;
}

void main() {
  Future<void> showTest(
      WidgetTester tester, CoreTestController test, TestSpeechBackend speech,
      {Size size = const Size(375, 812),
      ValueNotifier<bool>? paused,
      Future<void> Function()? save}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final pause = paused ?? ValueNotifier(false);
    if (paused == null) addTearDown(pause.dispose);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: ValueListenableBuilder<bool>(
            valueListenable: pause,
            builder: (context, value, child) => CoreSkillsTestScreen(
                paused: value,
                onClose: () {},
                onFinish: () {},
                controller: test,
                speechBackend: speech,
                saveResult: (_) async {
                  if (save != null) await save();
                }))));
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pump();
  }

  testWidgets(
      'reading cards really reorder via drag and keep the opening sentence locked',
      (tester) async {
    final test = atQuestion(30);
    addTearDown(test.dispose);
    await showTest(tester, test, TestSpeechBackend(),
        size: const Size(430, 1000));
    final first = find.byKey(const ValueKey('r01-2'));
    final last = find.byKey(const ValueKey('r01-1'));
    await tester.ensureVisible(last);
    await tester.pump();
    final target = tester.getTopLeft(first).dy + 10;
    final origin = tester.getCenter(last);
    await tester.timedDragFrom(
        origin, Offset(0, target - origin.dy), const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(test.order, [0, 1, 2, 3]);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    await tap(tester, 'NEXT');
    expect(test.answers.last.correct, isTrue);
    expect(test.question.id, 'r02');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final index in [0, 30, 45]) {
    testWidgets('no visible question counter in section at question $index',
        (tester) async {
      final test = atQuestion(index);
      addTearDown(test.dispose);
      await showTest(tester, test, TestSpeechBackend());
      expect(find.textContaining(RegExp(r'Question \d+ of \d+')), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
      expect(find.widgetWithText(ElevatedButton, 'NEXT'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final beginSpeech in [false, true]) {
    testWidgets(
        'Play immediately unlocks answers and NEXT without waiting for ${beginSpeech ? "completion" : "native startup"}',
        (tester) async {
      final test = atQuestion(45);
      addTearDown(test.dispose);
      final speech = TestSpeechBackend();
      await showTest(tester, test, speech);
      final answer = find.widgetWithText(
          OutlinedButton, listeningQuestions.first.choices[1]);
      final next = find.widgetWithText(ElevatedButton, 'NEXT');
      expect(tester.widget<OutlinedButton>(answer).onPressed, isNull);
      expect(tester.widget<ElevatedButton>(next).onPressed, isNull);
      await tester.tap(find.byTooltip('Play listening audio'));
      await tester.pump();
      if (beginSpeech) {
        speech.begin();
        await tester.pump();
      }
      expect(speech.pending!.isCompleted, isFalse);
      expect(tester.widget<OutlinedButton>(answer).onPressed, isNotNull);
      expect(tester.widget<ElevatedButton>(next).onPressed, isNull);
      await tap(tester, listeningQuestions.first.choices[1]);
      expect(tester.widget<ElevatedButton>(next).onPressed, isNotNull);
      final stops = speech.stops;
      final oldStarted = speech.started!;
      await tap(tester, 'NEXT');
      expect(speech.stops, greaterThan(stops));
      expect(speech.pending!.isCompleted, isTrue);
      expect(test.question.id, 'l02');
      expect(test.answers.last.correct, isTrue);
      oldStarted();
      await tester.pump();
      expect(find.text('Listen: 2 plays left'), findsOneWidget);
      final newAnswer = find.widgetWithText(
          OutlinedButton, listeningQuestions[1].choices.first);
      expect(tester.widget<OutlinedButton>(newAnswer).onPressed, isNull);
      expect(tester.widget<ElevatedButton>(next).onPressed, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final size in [const Size(320, 568), const Size(375, 812)]) {
    testWidgets('listening start/error/retry and two real plays at $size',
        (tester) async {
      final test = atQuestion(45);
      addTearDown(test.dispose);
      final speech = TestSpeechBackend()..failBeforeStart = true;
      await showTest(tester, test, speech, size: size);
      expect(find.text('Listen: 2 plays left'), findsOneWidget);
      expect(
          tester
              .widget<ElevatedButton>(
                  find.widgetWithText(ElevatedButton, 'NEXT'))
              .onPressed,
          isNull);
      await tester.ensureVisible(find.byTooltip('Play listening audio'));
      await tester.tap(find.byTooltip('Play listening audio'));
      await tester.pump();
      expect(find.text('Retry audio'), findsOneWidget);
      expect(find.text('Listen: 2 plays left'), findsOneWidget);
      speech.failBeforeStart = false;
      await tap(tester, 'Retry audio');
      expect(find.text('Listen: 2 plays left'),
          findsOneWidget); // No native start yet.
      speech.begin();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1100)));
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text('00:01'), findsOneWidget);
      expect(find.text('Listen: 1 play left'), findsOneWidget);
      speech.finish();
      await tester.pump();
      await tester.ensureVisible(find.byTooltip('Play listening audio'));
      await tester.tap(find.byTooltip('Play listening audio'));
      await tester.pump();
      speech.begin();
      speech.finish();
      await tester.pump();
      expect(find.text('Listen: 0 plays left'), findsOneWidget);
      final button = tester.widget<IconButton>(find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.tooltip == 'Play listening audio'));
      expect(button.onPressed, isNull);
      await tap(tester, listeningQuestions.first.choices[1]);
      await tap(tester, 'NEXT');
      expect(test.question.id, 'l02');
      expect(find.text('Listen: 2 plays left'), findsOneWidget);
      expect(speech.calls, 3); // One failure, two audible attempts.
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'question expiry and background/exit pause stop audio without leaking to next question',
      (tester) async {
    final test = atQuestion(45);
    addTearDown(test.dispose);
    final speech = TestSpeechBackend();
    final pause = ValueNotifier(false);
    addTearDown(pause.dispose);
    await showTest(tester, test, speech, paused: pause);
    await tester.tap(find.byTooltip('Play listening audio'));
    speech.begin();
    await tester.pump();
    pause.value = true;
    await tester.pump();
    expect(test.paused, isTrue);
    expect(speech.stops, greaterThan(0));
    expect(find.text('Listen: 1 play left'), findsOneWidget);
    final seconds = test.seconds;
    test.tick();
    expect(test.seconds, seconds);
    pause.value = false;
    await tester.pump();
    await tester.tap(find.byTooltip('Play listening audio'));
    speech.begin();
    await tester.pump();
    for (var i = 0; i < 105; i++) {
      test.tick();
    }
    await tester.pump();
    expect(test.question.id, 'l02');
    expect(find.text('Listen: 2 plays left'), findsOneWidget);
    expect(test.answers.last.answered, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'result saving failure is visible and retry preserves the calculated score',
      (tester) async {
    final test = atQuestion(54);
    addTearDown(test.dispose);
    var saves = 0;
    await showTest(tester, test, TestSpeechBackend(), save: () async {
      if (++saves == 1) throw StateError('Disk full');
    });
    test.submit(expired: true);
    await tester.pumpAndSettle();
    expect(find.text('Well done!'), findsOneWidget);
    expect(find.text('Retry saving'), findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Get my certificate'))
            .onPressed,
        isNull);
    await tap(tester, 'Retry saving');
    await tester.pump();
    expect(saves, 2);
    expect(find.text('Demo score · 0 / 55 correct'), findsOneWidget);
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
