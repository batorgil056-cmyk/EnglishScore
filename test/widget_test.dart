import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:englishscore_intro/main.dart';

void main() {
  testWidgets('EnglishScore app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const EnglishScoreIntroApp());

    expect(find.byType(EnglishScoreIntroApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
