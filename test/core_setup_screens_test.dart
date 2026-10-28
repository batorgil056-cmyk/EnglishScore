import 'package:englishscore_intro/core_setup_screens.dart';
import 'package:englishscore_intro/core_skills_pretest.dart';
import 'package:englishscore_intro/core_test_flow.dart';
import 'package:englishscore_intro/dashboard.dart';
import 'package:englishscore_intro/demo_session.dart';
import 'package:englishscore_intro/local_account.dart';
import 'package:englishscore_intro/test_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pump();
  }

  Future<void> begin(WidgetTester tester, {bool securityOn = false}) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    SharedPreferences.setMockInitialValues(
        {LocalAccount.emailKey: 'preserved@example.org'});
    await DemoSession.signIn('preserved@example.org');
    addTearDown(DemoSession.signOut);
    await DemoResults.preview(2).save();
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: const EnglishScoreDashboard()));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Test again').first);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tap(tester, find.text("I don't have a code"));
    await tester.pumpAndSettle();
    await tap(tester, find.text('OK'));
    await tester.pumpAndSettle();
    if (securityOn) {
      await tap(tester, find.text('On'));
      await tester.pumpAndSettle();
    }
    await tap(tester, find.text('Next'));
    expect(find.text("Let's get you\nset up"), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  SetupStage stage(WidgetTester tester) =>
      tester.widget<CoreSetupScreens>(find.byType(CoreSetupScreens)).stage;

  Future<void> arrive(WidgetTester tester, SetupStage target) async {
    await begin(tester);
    if (target == SetupStage.intro) return;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    if (target == SetupStage.volume) return;
    await tap(tester, find.text('Yes'));
    await tester.pumpAndSettle();
    if (target == SetupStage.microphone) return;
    await tap(tester, find.widgetWithText(ElevatedButton, 'OK'));
    await tester.pumpAndSettle();
    if (target == SetupStage.camera) return;
    await tap(tester, find.widgetWithText(ElevatedButton, 'OK'));
    await tester.pumpAndSettle();
    if (target == SetupStage.review) {
      await tap(tester, find.text('Use demo camera'));
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Capture demo image'));
      await tester.pumpAndSettle();
    }
  }

  for (final on in [false, true]) {
    testWidgets('security ${on ? 'On' : 'Off'} Next shows intro then Volume',
        (tester) async {
      await begin(tester, securityOn: on);
      expect(stage(tester), SetupStage.intro);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(stage(tester), SetupStage.volume);
      expect(find.text('Volume check'), findsOneWidget);
      expect(find.text('Demo animation — no audio is playing'), findsOneWidget);
      expect(find.bySemanticsLabel('Volume, current step'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'full flow opens/dismisses info popups and supports explicit demo capture review',
      (tester) async {
    await arrive(tester, SetupStage.volume);
    await tap(tester, find.text('Yes'));
    await tester.pumpAndSettle();
    expect(stage(tester), SetupStage.microphone);
    expect(find.bySemanticsLabel('Microphone, current step'), findsOneWidget);
    expect(find.bySemanticsLabel('Volume, completed step'), findsOneWidget);
    expect(
        find.text(
            'You should be alone in a quiet place.\nYou must not talk during the exam,\nand you must not read the questions\naloud.'),
        findsOneWidget);
    await tap(tester, find.text('Find out more'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(
        find.text(
            'EnglishScore uses the microphone to detect if you or someone else is talking. Potential violations are recorded and reviewed.'),
        findsOneWidget);
    await tap(tester,
        find.descendant(of: find.byType(Dialog), matching: find.text('OK')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(stage(tester), SetupStage.microphone);
    await tap(tester, find.widgetWithText(ElevatedButton, 'OK'));
    await tester.pumpAndSettle();
    expect(stage(tester), SetupStage.camera);
    expect(find.bySemanticsLabel('Camera, current step'), findsOneWidget);
    expect(find.bySemanticsLabel('Microphone, completed step'), findsOneWidget);
    await tap(tester, find.text('Find out more'));
    await tester.pumpAndSettle();
    expect(find.text('Why does EnglishScore use the camera?'), findsOneWidget);
    await tap(tester,
        find.descendant(of: find.byType(Dialog), matching: find.text('OK')));
    await tester.pumpAndSettle();
    expect(stage(tester), SetupStage.camera);
    await tap(tester, find.widgetWithText(ElevatedButton, 'OK'));
    await tester.pumpAndSettle();
    expect(stage(tester), SetupStage.selfie);
    expect(find.text('Take a selfie'), findsOneWidget);
    expect(find.text('Camera preview unavailable'), findsOneWidget);
    await tap(tester, find.text('Use demo camera'));
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Capture demo image'));
    await tester.pumpAndSettle();
    expect(stage(tester), SetupStage.review);
    expect(find.text('Simulated capture\nNo photo was taken'), findsOneWidget);
    await tap(tester, find.text('Retake'));
    await tester.pumpAndSettle();
    expect(stage(tester), SetupStage.selfie);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Volume No retries without passing the step and demo animation updates',
      (tester) async {
    await arrive(tester, SetupStage.volume);
    final waveform = find.byWidgetPredicate((w) =>
        w is CustomPaint &&
        w.painter.runtimeType.toString() == '_DemoWavePainter');
    final original = tester.widget<CustomPaint>(waveform).painter;
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<CustomPaint>(waveform).painter, isNot(same(original)));
    await tap(tester, find.text('No'));
    await tester.pumpAndSettle();
    expect(find.text('Try the volume check again'), findsOneWidget);
    await tap(tester, find.text('Retry'));
    await tester.pumpAndSettle();
    expect(stage(tester), SetupStage.volume);
    expect(find.text('Volume check'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final atQuestions in [false, true]) {
    testWidgets(
        'selfie review connects to test flow; shared exit at ${atQuestions ? "questions" : "room intro"}',
        (tester) async {
      await arrive(tester, SetupStage.review);
      await tap(tester, find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(CoreTestFlow), findsOneWidget);
      if (atQuestions) {
        await tap(tester, find.text('Start scanning'));
        for (var i = 0; i < 4; i++) {
          await tap(tester, find.text('Swipe right or tap to scan →'));
        }
        await tap(tester, find.text('OK'));
        await tap(tester, find.text('I agree'));
        await tester.pump(const Duration(seconds: 2));
        await tap(tester, find.text('Start the test'));
        await tap(tester, find.text('Start'));
      }
      final heading =
          atQuestions ? 'Leaving the restaurant' : 'Scanning your room';
      expect(find.text(heading), findsOneWidget);
      await tap(tester, find.byTooltip('Close pre-test'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 45));
      await tap(tester, find.text('Go back'));
      expect(find.text(heading), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, find.text('Exit the test'));
      await tester.pumpAndSettle();
      expect(find.byType(CoreSkillsPretest), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'Home and Reports reload the saved Core Skills result after the test route closes',
      (tester) async {
    await arrive(tester, SetupStage.review);
    await tap(tester, find.text('Done'));
    await tester.pumpAndSettle();
    await DemoResults.saveCore(const DemoResult(327, 'B1'));
    await tap(tester, find.byTooltip('Close pre-test'));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Exit the test'));
    await tester.pumpAndSettle();
    expect(find.text('327'), findsOneWidget);
    await tap(tester, find.text('All Reports'));
    await tester.pumpAndSettle();
    expect(find.text('327'), findsOneWidget);
    expect(find.text('Demo reports — sample results'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final target in SetupStage.values) {
    for (final systemBack in [false, true]) {
      testWidgets(
          '${target.name} ${systemBack ? 'Back' : 'X'} confirms exit and preserves login/results',
          (tester) async {
        await arrive(tester, target);
        final prefs = await SharedPreferences.getInstance();
        final saved = {for (final key in prefs.getKeys()) key: prefs.get(key)};
        Future<void> requestExit() async {
          if (systemBack) {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(find.byTooltip('Close pre-test'));
          }
          await tester.pumpAndSettle();
          expect(find.text('Are you sure you want\nto exit?'), findsOneWidget);
        }

        await requestExit();
        await tap(tester, find.text('Go back'));
        // Don't advance the paused introduction's timer while checking its state.
        await tester.pump(const Duration(milliseconds: 350));
        expect(stage(tester), target);
        await requestExit();
        await tap(tester, find.text('Exit the test'));
        await tester.pumpAndSettle();
        expect(find.byType(CoreSkillsPretest), findsNothing);
        expect(find.text('Home'), findsOneWidget);
        expect(DemoSession.isSignedIn, isTrue);
        expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, saved);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final target in [SetupStage.microphone, SetupStage.camera]) {
    testWidgets(
        'system Back on ${target.name} info uses shared exit confirmation',
        (tester) async {
      await arrive(tester, target);
      await tap(tester, find.text('Find out more'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want\nto exit?'), findsOneWidget);
      await tap(tester, find.text('Go back'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(stage(tester), target);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, find.text('Exit the test'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(CoreSkillsPretest), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
