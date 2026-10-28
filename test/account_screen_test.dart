import 'package:englishscore_intro/account_screen.dart';
import 'package:englishscore_intro/dashboard.dart';
import 'package:englishscore_intro/local_account.dart';
import 'package:englishscore_intro/test_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
      'local profile retains the submitted email and replaces it on next sign-in',
      () async {
    SharedPreferences.setMockInitialValues({});
    expect(await LocalAccount.loadEmail(), isNull);
    await LocalAccount.saveEmail('  entered.address@example.org  ');
    expect(await LocalAccount.loadEmail(), 'entered.address@example.org');
    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getString(LocalAccount.emailKey), 'entered.address@example.org');
    await LocalAccount.saveEmail('another.address@example.org');
    expect(await LocalAccount.loadEmail(), 'another.address@example.org');
  });

  void useIPhoneXS(WidgetTester tester) {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app(Widget home) => MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(375, 812),
                padding: EdgeInsets.only(top: 44, bottom: 34)),
            child: home),
      );

  testWidgets(
      'Account opens from Home menu, loads saved email, and returns to Home',
      (tester) async {
    useIPhoneXS(tester);
    SharedPreferences.setMockInitialValues(
        {LocalAccount.emailKey: 'signed.in@example.org'});
    await tester.pumpWidget(app(const EnglishScoreDashboard()));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text('signed.in@example.org'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'missing email has no fake fallback and help explains unavailable support',
      (tester) async {
    useIPhoneXS(tester);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app(const AccountScreen()));
    await tester.pumpAndSettle();
    expect(find.text('No email saved on this device.'), findsOneWidget);
    await tester.tap(find.text('Get help'));
    await tester.pumpAndSettle();
    expect(find.text('Support not configured'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'deletion cancellation and confirmation preserve email and test states',
      (tester) async {
    useIPhoneXS(tester);
    SharedPreferences.setMockInitialValues(
        {LocalAccount.emailKey: 'retained@example.org'});
    await DemoResults.preview(2).save();
    final prefs = await SharedPreferences.getInstance();
    final originalResults = prefs.getString(DemoResults.storageKey);
    await tester.pumpWidget(app(const AccountScreen()));
    await tester.pumpAndSettle();
    final delete = find.widgetWithText(TextButton, 'Delete your account');
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await LocalAccount.loadEmail(), 'retained@example.org');
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Account deletion not configured'), findsOneWidget);
    expect(await LocalAccount.loadEmail(), 'retained@example.org');
    expect(prefs.getString(DemoResults.storageKey), originalResults);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long email wraps without overflow at iPhone XS size',
      (tester) async {
    useIPhoneXS(tester);
    SharedPreferences.setMockInitialValues({
      LocalAccount.emailKey: '${'very.long.address.' * 6}person@example.org',
    });
    await tester.pumpWidget(app(const AccountScreen()));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.widgetWithText(TextButton, 'Delete your account'));
    expect(tester.takeException(), isNull);
  });
}
