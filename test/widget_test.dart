import 'package:flutter_test/flutter_test.dart';

import 'package:cronos/main.dart';

void main() {
  testWidgets('Cronos app boots and shows the Hoy dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const CronosApp());
    await tester.pump();

    expect(find.text('Hoy'), findsOneWidget);
  });
}
