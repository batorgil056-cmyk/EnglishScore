import 'package:englishscore_intro/test_results.dart';
import 'package:englishscore_intro/dashboard.dart';
import 'package:englishscore_intro/core_test/score_details.dart';
import 'package:englishscore_intro/core_test/report_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_history_test.dart' show datedResult;

void main() {
  Future<void> configure(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  for (final size in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(430, 932)
  ]) {
    testWidgets(
        'one scrollable details page, share and existing certificate flow fit $size',
        (tester) async {
      await configure(tester, size);
      final result = DemoResult(250, 'B1',
          id: 'specific-report',
          completedAt: DateTime.utc(2026, 3, 4, 12),
          grammar: 100,
          vocabulary: 200,
          reading: 300,
          listening: 400);
      String? shared;
      await tester.pumpWidget(MaterialApp(
          home: CoreScoreDetails(
              result: result,
              onShare: (text, origin) async {
                shared = text;
                expect(origin.width, greaterThan(0));
                expect(origin.height, greaterThan(0));
              })));
      await tester.pumpAndSettle();
      expect(find.text('Tested on ${formatTestDate(result.completedAt)}'),
          findsOneWidget);
      expect(find.text('Demo result'), findsNothing);
      expect(find.textContaining('Not recorded'), findsNothing);
      expect(
          find.byKey(const ValueKey('incomplete-core-result')), findsNothing);
      expect(find.text('Grammar • 100'), findsOneWidget);
      expect(find.text('Vocabulary • 200'), findsOneWidget);
      expect(find.text('Reading • 300'), findsOneWidget);
      expect(find.text('Listening • 400'), findsOneWidget);
      await tap(tester, find.text('Share'));
      expect(shared, contains('250/600'));
      expect(shared, contains('Grammar: 100'));
      await tap(tester, find.text('Get my certificate'));
      expect(find.text('Pick your certificate'), findsOneWidget);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('certificate-preview-score')))
              .data,
          '250');
      await tap(tester, find.text("I don't need a certificate"));
      await tap(tester, find.text('Later'));
      expect(find.byType(CoreScoreDetails), findsOneWidget);
      await tester.ensureVisible(find.text('Understand CEFR score'));
      await tester.pumpAndSettle();
      expect(find.text('At B1 • Intermediate you can:'), findsOneWidget);
      expect(find.text('Pre A1'), findsOneWidget);
      expect(find.textContaining('not independently verified'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('score-details-scroll')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
      'Home uses latest, reports newest first mark the best, and each opens its own stored details',
      (tester) async {
    await configure(tester, const Size(375, 812));
    SharedPreferences.setMockInitialValues({});
    final older =
        datedResult('older', 410, DateTime.utc(2026, 1, 1, 12), cefr: 'B2');
    final newer =
        datedResult('newer', 220, DateTime.utc(2026, 1, 2, 12), cefr: 'A2');
    await DemoResults.saveCore(older);
    await DemoResults.saveCore(newer);
    await tester.pumpWidget(const MaterialApp(home: EnglishScoreDashboard()));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<CompletedCoreCard>(find.byType(CompletedCoreCard))
            .result
            .id,
        'newer');
    expect(find.text('A2 • Elementary'), findsOneWidget);
    expect(find.text('Complete Core Skills to unlock'), findsNothing);
    await tap(tester, find.text('Certificate'));
    expect(find.text('Pick your certificate'), findsOneWidget);
    await tap(tester, find.text("I don't need a certificate"));
    await tap(tester, find.text('Later'));
    await tap(tester, find.text('All Reports'));
    final cards =
        tester.widgetList<CoreReportCard>(find.byType(CoreReportCard)).toList();
    expect(cards.map((c) => c.result.id), ['newer', 'older']);
    expect(cards.first.best, isFalse);
    expect(cards.last.best, isTrue);
    await tap(tester, find.byKey(const ValueKey('report-older')));
    expect(
        tester
            .widget<CoreScoreDetails>(find.byType(CoreScoreDetails))
            .result
            .id,
        'older');
    expect(find.text('B2 • Upper Intermediate'), findsOneWidget);
    await tap(tester, find.byTooltip('Back'));
    await tap(tester, find.byKey(const ValueKey('report-newer')));
    expect(
        tester
            .widget<CoreScoreDetails>(find.byType(CoreScoreDetails))
            .result
            .id,
        'newer');
    expect(find.text('A2 • Elementary'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'incomplete historical result is explicit instead of treating missing sections as zero',
      (tester) async {
    await configure(tester, const Size(375, 812));
    const result =
        DemoResult(410, 'B2', grammar: 120, reading: 140, vocabulary: 160);
    await tester
        .pumpWidget(const MaterialApp(home: CoreScoreDetails(result: result)));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('incomplete-core-result')), findsOneWidget);
    expect(find.text('Grammar • 120'), findsOneWidget);
    expect(find.text('Reading • 140'), findsOneWidget);
    expect(find.text('Vocabulary • 160'), findsOneWidget);
    expect(find.text('Listening • —'), findsOneWidget);
    expect(find.textContaining('Not recorded'), findsNothing);
    expect(find.text('Demo result'), findsNothing);
    expect(find.text('410'), findsOneWidget);
    expect(result.hasSectionScores, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
