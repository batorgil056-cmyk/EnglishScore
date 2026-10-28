import 'dart:typed_data';
import 'package:englishscore_intro/core_test/question_data.dart';
import 'package:englishscore_intro/test_results.dart';
import 'package:englishscore_intro/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/test_speech_backend.dart';
import 'package:englishscore_intro/core_test_flow.dart';
import 'package:englishscore_intro/selfie_camera_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Camera implements SelfieCameraBackend {
  _Camera(this.device);
  final bool device;
  int starts = 0;
  int stops = 0;
  @override
  Future<SelfieEnvironment> environment() async =>
      device ? SelfieEnvironment.iosDevice : SelfieEnvironment.iosSimulator;
  @override
  Future<void> start() async {
    starts++;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Widget preview() => const ColoredBox(color: Colors.blue);
  @override
  Future<Uint8List> capture() async =>
      throw StateError('Room scan must not capture');
}

void main() {
  Future<void> tap(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
  }

  Future<void> start(WidgetTester tester,
      {Size size = const Size(375, 812),
      _Camera? camera,
      ValueNotifier<bool>? paused,
      VoidCallback? finish}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final pause = paused ?? ValueNotifier(false);
    if (paused == null) addTearDown(pause.dispose);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
        home: ValueListenableBuilder<bool>(
            valueListenable: pause,
            builder: (_, value, child) => CoreTestFlow(
                paused: value,
                onClose: () {},
                onFinish: finish ?? () {},
                cameraBackend: camera ?? _Camera(false),
                speechBackend: TestSpeechBackend()..instant = true))));
    await tester.pump();
  }

  Future<void> toIntro(WidgetTester tester) async {
    await tap(tester, 'Start scanning');
    for (var i = 0; i < 4; i++) {
      await tap(tester, 'Swipe right or tap to scan →');
    }
    expect(find.text('Scanning complete'), findsOneWidget);
    await tap(tester, 'OK');
    expect(find.text('Test rules'), findsOneWidget);
    await tap(tester, 'I agree');
    await tester.pump(const Duration(seconds: 2));
    await tap(tester, 'Start the test');
    expect(find.text('Starts in 30'), findsOneWidget);
  }

  for (final size in [
    const Size(375, 812),
    const Size(320, 568),
    const Size(430, 932)
  ]) {
    testWidgets('complete sequence and answer selection at $size',
        (tester) async {
      var finished = false;
      final camera = _Camera(false);
      await start(tester,
          size: size, camera: camera, finish: () => finished = true);
      await toIntro(tester);
      await tap(tester, 'Start');
      expect(find.text('Warning - Talking is not allowed'), findsNothing);
      expect(find.text('Leaving the restaurant'), findsOneWidget);
      for (final question in coreQuestions) {
        if (question == readingQuestions.first ||
            question == listeningQuestions.first) {
          expect(find.text('Part ${question.part.number}'), findsOneWidget);
          expect(find.text('Starts in 30'), findsOneWidget);
          await tap(tester, 'Start');
        }
        if (question.kind != QuestionKind.ordering) {
          expect(
              tester
                  .widget<ElevatedButton>(
                      find.widgetWithText(ElevatedButton, 'NEXT'))
                  .onPressed,
              isNull);
          if (question.kind == QuestionKind.listening) {
            await tester.ensureVisible(find.byTooltip('Play listening audio'));
            await tester.tap(find.byTooltip('Play listening audio'));
            await tester.pump();
          }
          await tap(tester, question.choices[question.correctChoice!]);
        }
        await tap(tester, 'NEXT');
      }
      await tester.pumpAndSettle();
      expect(find.text('Well done!'), findsOneWidget);
      final generated = (await DemoResults.load()).results['core']!;
      expect(generated.score, inInclusiveRange(400, 450));
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('animated-result-score')))
              .data,
          generated.score.toString());
      expect(find.text('CEFR B2 · Upper Intermediate'), findsOneWidget);
      expect(find.text('Demo score · 50 / 55 correct'), findsOneWidget);
      expect(
          (await DemoResults.load()).results['core']!.score, generated.score);
      await tap(tester, 'Get my certificate');
      await tap(tester, "I don't need a certificate");
      await tap(tester, 'Later');
      expect(finished, isTrue);
      expect(camera.starts, 0);
      await tester.pumpWidget(const MaterialApp(home: EnglishScoreDashboard()));
      await tester.pumpAndSettle();
      expect(find.text(generated.score.toString()), findsOneWidget);
      expect(find.text('Complete Core Skills to unlock'), findsNothing);
      await tap(tester, 'All Reports');
      await tester.pumpAndSettle();
      expect(find.text(generated.score.toString()), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'countdowns pause and advance automatically without stale selections',
      (tester) async {
    final pause = ValueNotifier(false);
    addTearDown(pause.dispose);
    await start(tester, paused: pause);
    await toIntro(tester);
    pause.value = true;
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('Starts in 30'), findsOneWidget);
    pause.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Leaving the restaurant'), findsOneWidget);
    await tester.pump(const Duration(seconds: 42));
    expect(find.text('A weekend plan'), findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'NEXT'))
            .onPressed,
        isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('real preview needs explicit action and stops on exit/background',
      (tester) async {
    final camera = _Camera(true);
    final pause = ValueNotifier(false);
    addTearDown(pause.dispose);
    await start(tester, camera: camera, paused: pause);
    await tap(tester, 'Start scanning');
    expect(camera.starts, 0);
    await tap(tester, 'Enable rear camera');
    expect(camera.starts, 1);
    pause.value = true;
    await tester.pump();
    expect(camera.stops, greaterThan(0));
    pause.value = false;
    await tester.pump();
    await tap(tester, 'Enable rear camera');
    final stops = camera.stops;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(camera.stops, greaterThan(stops));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
