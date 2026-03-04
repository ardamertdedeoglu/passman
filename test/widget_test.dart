import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman_frontend/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PassManApp()));
    await tester.pumpAndSettle();

    // Verify the login screen is shown
    expect(find.text('PassMan'), findsOneWidget);
    expect(find.text('Unlock your secure vault'), findsOneWidget);
  });
}
