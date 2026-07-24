import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cronos/shared/widgets/mascot/cronos_mascot.dart';

void main() {
  for (final state in MascotState.values) {
    testWidgets('se pinta sin errores en estado $state', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Center(child: CronosMascot(size: 160, state: state)),
      ));
      // Varios frames para recorrer blink, mirada e idle/celebrate/etc.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(CronosMascot), findsOneWidget);
    });
  }

  testWidgets('cambiar de estado dispara la transición sin errores', (tester) async {
    var state = MascotState.idle;
    await tester.pumpWidget(StatefulBuilder(builder: (context, setState) {
      return MaterialApp(
        home: Center(
          child: GestureDetector(
            onTap: () => setState(() => state = MascotState.celebrate),
            child: CronosMascot(size: 160, state: state),
          ),
        ),
      );
    }));

    await tester.tap(find.byType(CronosMascot));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
  });
}
