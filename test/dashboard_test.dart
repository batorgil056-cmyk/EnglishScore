import 'dart:convert';
import 'package:englishscore_intro/dashboard.dart';
import 'package:englishscore_intro/test_results.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('demo state survives reload and invalid data recovers safely', () async {
    SharedPreferences.setMockInitialValues({});
    await DemoResults.preview(2).save();
    final loaded = await DemoResults.load();
    expect(loaded.results.length, 3);
    expect(loaded.results['core']!.score, 410);
    SharedPreferences.setMockInitialValues({
      DemoResults.storageKey: jsonEncode({
        'speaking': {'score': 360, 'cefr': 'B1'}
      }),
    });
    expect((await DemoResults.load()).results, isEmpty);
    SharedPreferences.setMockInitialValues({DemoResults.storageKey: 'broken'});
    expect((await DemoResults.load()).results, isEmpty);
  });

  for (var state = 0; state < 3; state++) {
    testWidgets('state $state fits iPhone XS and reports reflect completion',
        (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await DemoResults.preview(state).save();
      await tester.pumpWidget(const MaterialApp(home: EnglishScoreDashboard()));
      await tester.pumpAndSettle();
      expect(find.text('Complete Core Skills to unlock'),
          state == 0 ? findsNWidgets(2) : findsNothing);
      expect(
          find.text('Test again'),
          findsNWidgets(state == 0
              ? 0
              : state == 1
                  ? 1
                  : 3));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('All Reports'));
      await tester.pumpAndSettle();
      expect(find.text('Demo reports — sample results'), findsNothing);
      expect(find.text('Take a test to start\ntracking your scores'),
          state == 0 ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'preview menu saves state and restores it on dashboard recreation',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: EnglishScoreDashboard()));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Demo UI states'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3. All tests completed'));
    await tester.pumpAndSettle();
    expect((await DemoResults.load()).results.length, 3);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MaterialApp(home: EnglishScoreDashboard()));
    await tester.pumpAndSettle();
    expect(find.text('Test again'), findsNWidgets(3));
    await tester.tap(find.text('Certificate').first);
    await tester.pumpAndSettle();
    expect(find.text('Pick your certificate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
