import 'package:englishscore_intro/core_skills_pretest.dart';
import 'package:englishscore_intro/dashboard.dart';
import 'package:englishscore_intro/demo_session.dart';
import 'package:englishscore_intro/local_account.dart';
import 'package:englishscore_intro/test_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  void useIPhoneXS(WidgetTester tester) {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> start(WidgetTester tester,
      {int state = 0, bool loading = false}) async {
    useIPhoneXS(tester);
    SharedPreferences.setMockInitialValues(
        {LocalAccount.emailKey: 'preserved@example.org'});
    await DemoResults.preview(state).save();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: const MediaQuery(
        data: MediaQueryData(
            size: Size(375, 812),
            padding: EdgeInsets.only(top: 44, bottom: 34)),
        child: EnglishScoreDashboard(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester
        .tap(find.text(state == 0 ? 'Start the test' : 'Test again').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text("Let's get you ready for\nthe test"), findsOneWidget);
    if (loading) return;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  Future<void> noCode(WidgetTester tester) async {
    final button = find.text("I don't have a code");
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Finder art(String name) => find.byWidgetPredicate((w) =>
      w is SvgPicture &&
      w.bytesLoader is SvgAssetLoader &&
      (w.bytesLoader as SvgAssetLoader).assetName ==
          'assets/pretest/$name.svg');

  testWidgets('loading, no-code, About, Off/On security and setup introduction',
      (tester) async {
    await start(tester);
    await noCode(tester);
    expect(
        find.text('A 30–40 minute test of your\nCore Skills'), findsOneWidget);
    for (final topic in ['Grammar and vocabulary', 'Reading', 'Listening']) {
      expect(find.text(topic), findsOneWidget);
    }
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Test security'), findsOneWidget);
    expect(art('certificate_off'), findsOneWidget);
    expect(find.textContaining('UI preview only.'), findsNothing);
    expect(find.bySemanticsLabel('Off'), findsOneWidget);
    expect(
        tester
            .getSemantics(find.text('Off'))
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isTrue);
    await tester.tap(find.text('On'));
    await tester.pumpAndSettle();
    expect(art('certificate_on'), findsOneWidget);
    expect(find.textContaining('UI preview only.'), findsNothing);
    expect(find.text('✓ Get a certificate'), findsOneWidget);
    expect(
        tester
            .getSemantics(find.text('On'))
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isTrue);
    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(art('certificate_off'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text("Let's get you\nset up"), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Volume check'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Connect Code form never validates, submits or saves codes/names',
      (tester) async {
    await start(tester);
    final prefs = await SharedPreferences.getInstance();
    final original = {for (final key in prefs.getKeys()) key: prefs.get(key)};
    final yes = find.text('Yes, enter the Connect Code');
    await tester.ensureVisible(yes);
    await tester.tap(yes);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(3));
    final apply = find.widgetWithText(ElevatedButton, 'Apply Code');
    expect(tester.widget<ElevatedButton>(apply).onPressed, isNull);
    await tester.enterText(find.byType(TextField).at(0), 'UNVERIFIED-CODE');
    await tester.enterText(find.byType(TextField).at(1), 'Example');
    await tester.enterText(find.byType(TextField).at(2), 'Person');
    await tester.pumpAndSettle();
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(find.text('Connect Code verification unavailable'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await noCode(tester);
    expect(find.text('About the test'), findsOneWidget);
    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, original);
    await tester.tap(find.byTooltip('Close pre-test'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want\nto exit?'), findsOneWidget);
    await tester.ensureVisible(find.text('Exit the test'));
    await tester.tap(find.text('Exit the test'));
    await tester.pumpAndSettle();
    expect(find.byType(CoreSkillsPretest), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Core Skills Test again starts prep and system Back preserves security until confirmed',
      (tester) async {
    await start(tester, state: 2);
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(DemoResults.storageKey);
    await noCode(tester);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want\nto exit?'), findsOneWidget);
    await tester.ensureVisible(find.text('Go back'));
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.text('Test security'), findsOneWidget);
    expect(prefs.getString(DemoResults.storageKey), saved);
    expect(await LocalAccount.loadEmail(), 'preserved@example.org');
    expect(tester.takeException(), isNull);
  });

  Future<void> arrive(WidgetTester tester, String step) async {
    await start(tester, state: 2, loading: step == 'loading');
    if (step == 'loading' || step == 'prompt') return;
    if (step == 'connect') {
      final yes = find.text('Yes, enter the Connect Code');
      await tester.ensureVisible(yes);
      await tester.tap(yes);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'MY-CODE');
      await tester.enterText(find.byType(TextField).at(1), 'First');
      await tester.enterText(find.byType(TextField).at(2), 'Last');
      await tester.pumpAndSettle();
      return;
    }
    await noCode(tester);
    if (step == 'off' || step == 'on') {
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      if (step == 'on') {
        await tester.tap(find.text('On'));
        await tester.pumpAndSettle();
      }
    }
  }

  Future<void> checkStep(WidgetTester tester, String step) async {
    if (step == 'connect') {
      expect(
          tester
              .widget<TextField>(find.byType(TextField).at(0))
              .controller!
              .text,
          'MY-CODE');
      expect(
          tester
              .widget<TextField>(find.byType(TextField).at(1))
              .controller!
              .text,
          'First');
      expect(
          tester
              .widget<TextField>(find.byType(TextField).at(2))
              .controller!
              .text,
          'Last');
    } else if (step == 'off' || step == 'on') {
      expect(art('certificate_$step'), findsOneWidget);
      expect(find.textContaining('UI preview only.'), findsNothing);
    } else if (step == 'prompt') {
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Yes, enter the Connect Code'), findsOneWidget);
    } else if (step == 'about') {
      expect(find.text('About the test'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    } else {
      expect(find.text("Let's get you ready for\nthe test"), findsOneWidget);
    }
  }

  for (final step in ['about', 'connect', 'off', 'on', 'prompt', 'loading']) {
    for (final action in ['X', 'system back']) {
      if (action == 'X' && (step == 'prompt' || step == 'loading')) continue;
      testWidgets(
          '$action on $step: Go back retains setup; Exit returns Home and preserves saved data',
          (tester) async {
        await arrive(tester, step);
        await DemoSession.signIn('preserved@example.org');
        addTearDown(DemoSession.signOut);
        final prefs = await SharedPreferences.getInstance();
        final saved = {for (final key in prefs.getKeys()) key: prefs.get(key)};
        Future<void> confirm() async {
          if (action == 'X') {
            final close = tester.widget<IconButton>(find.descendant(
                of: find.byType(CoreSkillsPretest),
                matching: find.byType(IconButton)));
            // Simulate two queued requests before the modal builds. The
            // duplicate-request guard must still create only one popup.
            close.onPressed!();
            close.onPressed!();
          } else {
            await tester.binding.handlePopRoute();
          }
          await tester.pumpAndSettle();
          expect(find.text('Are you sure you want\nto exit?'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        await confirm();
        await tester.ensureVisible(find.text('Go back'));
        await tester.tap(find.text('Go back'));
        await tester.pump();
        if (step == 'loading') {
          await tester.pump(const Duration(milliseconds: 350));
        } else {
          await tester.pumpAndSettle();
        }
        await checkStep(tester, step);
        await confirm();
        await tester.ensureVisible(find.text('Exit the test'));
        await tester.tap(find.text('Exit the test'));
        await tester.pumpAndSettle();
        expect(find.byType(CoreSkillsPretest), findsNothing);
        expect(find.byType(Dialog), findsNothing);
        expect(find.text('Home'), findsOneWidget);
        expect(DemoSession.isSignedIn, isTrue);
        expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, saved);
        await tester.tap(find.text('Test again').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text("Let's get you ready for\nthe test"), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.text('Yes, enter the Connect Code'), findsOneWidget);
        // Every new route starts afresh, without prior form/selector values.
        if (step == 'connect') {
          final yes = find.text('Yes, enter the Connect Code');
          await tester.ensureVisible(yes);
          await tester.tap(yes);
          await tester.pumpAndSettle();
          for (final field
              in tester.widgetList<TextField>(find.byType(TextField))) {
            expect(field.controller!.text, isEmpty);
          }
        }
        await noCode(tester);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(art('certificate_off'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'exiting a Core Skills retake opened from Reports returns to Home',
      (tester) async {
    await arrive(tester, 'about');
    await tester.tap(find.byTooltip('Close pre-test'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Exit the test'));
    await tester.tap(find.text('Exit the test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Reports'));
    await tester.pumpAndSettle();
    final coreCard = find
        .ancestor(
            of: find.text('CORE SKILLS TEST'), matching: find.byType(ClipRRect))
        .first;
    final retake =
        find.descendant(of: coreCard, matching: find.text('Test again'));
    await tester.ensureVisible(retake);
    await tester.pumpAndSettle();
    await tester.tap(retake);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await noCode(tester);
    await tester.tap(find.byTooltip('Close pre-test'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Exit the test'));
    await tester.tap(find.text('Exit the test'));
    await tester.pumpAndSettle();
    expect(find.byType(CoreSkillsPretest), findsNothing);
    expect(find.text('Demo reports — sample results'), findsNothing);
    expect(find.text('CORE SKILLS TEST'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'queued duplicate confirmation actions cannot pop the setup twice',
      (tester) async {
    await arrive(tester, 'connect');
    await tester.tap(find.byTooltip('Close pre-test'));
    await tester.pumpAndSettle();
    final goBack = tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Go back'))
        .onPressed!;
    goBack();
    goBack();
    await tester.pumpAndSettle();
    await checkStep(tester, 'connect');
    await tester.tap(find.byTooltip('Close pre-test'));
    await tester.pumpAndSettle();
    final exit = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Exit the test'))
        .onPressed!;
    exit();
    exit();
    await tester.pumpAndSettle();
    expect(find.byType(CoreSkillsPretest), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back on exit confirmation acts as Go back',
      (tester) async {
    await arrive(tester, 'connect');
    await tester.tap(find.byTooltip('Close pre-test'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want\nto exit?'), findsNothing);
    await checkStep(tester, 'connect');
    expect(tester.takeException(), isNull);
  });
}
