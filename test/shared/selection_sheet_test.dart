import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cronos/shared/shared.dart';

void main() {
  // Reproduce la incidencia: con muchas opciones (p.ej. vincular con app,
  // una lista de apps instaladas) la hoja no dejaba scrollear y las
  // opciones de más abajo quedaban inalcanzables.
  testWidgets('con muchas opciones, la hoja scrollea hasta la última', (tester) async {
    final options = [for (var i = 0; i < 40; i++) 'Opción $i'];
    String? picked;

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                picked = await showSelectionSheet<String>(
                  context: context,
                  title: 'Elegí una',
                  options: options,
                  labelBuilder: (o) => o,
                );
              },
              child: const Text('abrir'),
            ),
          ),
        );
      }),
    ));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // La última opción no está en pantalla todavía: hay que poder
    // scrollear hasta ella dentro de la hoja.
    expect(find.text('Opción 39'), findsNothing);
    await tester.scrollUntilVisible(find.text('Opción 39'), 300, maxScrolls: 60);
    await tester.pumpAndSettle();
    expect(find.text('Opción 39'), findsOneWidget);

    await tester.tap(find.text('Opción 39'));
    await tester.pumpAndSettle();
    expect(picked, 'Opción 39');
  });
}
