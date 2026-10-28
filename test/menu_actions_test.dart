import 'package:englishscore_intro/dashboard.dart';
import 'package:englishscore_intro/demo_session.dart';
import 'package:englishscore_intro/local_account.dart';
import 'package:englishscore_intro/main.dart';
import 'package:englishscore_intro/menu_links.dart';
import 'package:englishscore_intro/test_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class FakeLauncher extends UrlLauncherPlatform {
  @override
  Null get linkDelegate => null;
  final calls = <({String url, LaunchOptions options})>[];
  final failures = <String>{};
  final exceptions = <String>{};
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    calls.add((url: url, options: options));
    if (exceptions.contains(url)) throw PlatformException(code: 'unavailable');
    return !failures.contains(url);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeLauncher launcher;
  late UrlLauncherPlatform original;
  setUp(() {
    original = UrlLauncherPlatform.instance;
    launcher = FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
    SharedPreferences.setMockInitialValues({});
    DemoSession.signOut();
  });
  tearDown(() {
    UrlLauncherPlatform.instance = original;
    DemoSession.signOut();
  });

  const expectedLinks = {
    'Test Guide':
        'https://es-mktg-assets.s3.eu-west-2.amazonaws.com/guide/englishscore-coreskills-guide-mobile.pdf',
    'Help': 'https://www.englishscore.com/help',
    'Privacy Policy': 'https://www.englishscore.com/privacy-policy',
    'Our Rules': 'https://www.englishscore.com/terms-of-use',
    '💜 EnglishScore': 'https://apps.apple.com/app/id1499806063',
  };

  test('Web uses every exact HTTPS destination and a new browser tab',
      () async {
    for (final entry in expectedLinks.entries) {
      expect(await const MenuLinks(isWeb: true).open(entry.key), isTrue);
      expect(launcher.calls.last.url, entry.value);
      expect(launcher.calls.last.options.webOnlyWindowName, '_blank');
      expect(launcher.calls.last.options.mode,
          PreferredLaunchMode.platformDefault);
    }
  });

  test(
      'iOS prefers EnglishScore review destination and falls back on false or exception',
      () async {
    const links = MenuLinks(platform: TargetPlatform.iOS);
    const review =
        'itms-apps://apps.apple.com/app/id1499806063?action=write-review';
    expect(await links.open('💜 EnglishScore'), isTrue);
    expect(launcher.calls.single.url, review);
    expect(launcher.calls.single.options.mode,
        PreferredLaunchMode.externalApplication);
    launcher.calls.clear();
    launcher.failures.add(review);
    expect(await links.open('💜 EnglishScore'), isTrue);
    expect(launcher.calls.map((call) => call.url),
        [review, expectedLinks['💜 EnglishScore']]);
    launcher.calls.clear();
    launcher.exceptions.add(review);
    expect(await links.open('💜 EnglishScore'), isTrue);
    expect(launcher.calls.last.url, expectedLinks['💜 EnglishScore']);
    launcher.failures.add(expectedLinks['💜 EnglishScore']!);
    expect(await links.open('💜 EnglishScore'), isFalse);
  });

  void useIPhoneXS(WidgetTester tester) {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Open menu'));
    await tester.pumpAndSettle();
  }

  for (final entry in expectedLinks.entries) {
    testWidgets('menu ${entry.key} launches its exact destination externally',
        (tester) async {
      useIPhoneXS(tester);
      await tester.pumpWidget(const MaterialApp(home: EnglishScoreDashboard()));
      await tester.pumpAndSettle();
      await openMenu(tester);
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(launcher.calls.single.url, entry.value);
      expect(launcher.calls.single.options.mode,
          PreferredLaunchMode.externalApplication);
      expect(find.text('Account'), findsNothing); // drawer closed
      expect(tester.takeException(), isNull);
    });
  }

  for (final throws in [false, true]) {
    testWidgets(
        'launch ${throws ? 'exception' : 'failure'} displays destination and error',
        (tester) async {
      useIPhoneXS(tester);
      (throws ? launcher.exceptions : launcher.failures)
          .add(expectedLinks['Help']!);
      await tester.pumpWidget(const MaterialApp(home: EnglishScoreDashboard()));
      await tester.pumpAndSettle();
      await openMenu(tester);
      await tester.tap(find.text('Help'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to open Help'), findsOneWidget);
      expect(find.text(expectedLinks['Help']!), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'logout clears session and back stack, retains profile/results, allows sign-in again',
      (tester) async {
    useIPhoneXS(tester);
    await DemoResults.preview(2).save();
    final prefs = await SharedPreferences.getInstance();
    final results = prefs.getString(DemoResults.storageKey);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: false),
      home: const IntroFlow(initialScreen: IntroScreen.signIn),
    ));
    Future<void> signIn() async {
      await tester.enterText(
          find.byType(TextField).at(0), 'entered@example.org');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pump();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(EnglishScoreDashboard), findsOneWidget);
      expect(DemoSession.isSignedIn, isTrue);
    }

    await signIn();
    await openMenu(tester);
    await tester.ensureVisible(find.text('Log Out'));
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(DemoSession.isSignedIn, isFalse);
    expect(DemoSession.email, isNull);
    expect(find.byType(EnglishScoreDashboard), findsNothing);
    expect(find.text('Sign in to your account'), findsOneWidget);
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(navigator.canPop(), isFalse);
    expect(await navigator.maybePop(), isFalse);
    expect(await LocalAccount.loadEmail(), 'entered@example.org');
    expect(prefs.getString(DemoResults.storageKey), results);
    await signIn();
    expect(prefs.getString(DemoResults.storageKey), results);
    expect(tester.takeException(), isNull);
  });

  test('saved profile is not automatically an authenticated session', () async {
    await LocalAccount.saveEmail('saved@example.org');
    expect(DemoSession.isSignedIn, isFalse);
    await DemoSession.signIn('saved@example.org');
    DemoSession.signOut();
    expect(DemoSession.isSignedIn, isFalse);
    expect(await LocalAccount.loadEmail(), 'saved@example.org');
    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getKeys(), {LocalAccount.emailKey}); // no persisted login token
  });
}
