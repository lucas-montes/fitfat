import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitfat/src/app.dart';

void main() {
  testWidgets('App launches and shows food screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FitFatApp()));

    // Default route is /diet, should show the Diet tabs.
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
  });
}
