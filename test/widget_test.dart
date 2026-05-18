import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/src/app.dart';

void main() {
  testWidgets('App launches and shows food screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FitFatApp()));

    // Default route is /food, should show the Food app bar title
    expect(find.widgetWithText(AppBar, 'Food'), findsOneWidget);
  });
}
