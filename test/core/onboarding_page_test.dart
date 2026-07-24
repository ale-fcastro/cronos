import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cronos/core/navigation/onboarding_page.dart';

void main() {
  testWidgets('recorrer las diapositivas con Siguiente llega a Empezar', (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingPage(onDone: () => done = true),
    ));

    expect(find.text('Hola, soy Cronos'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);

    // 3 toques en "Siguiente" recorren las 4 diapositivas.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Empezar'), findsOneWidget);
    await tester.tap(find.text('Empezar'));
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('"Omitir" llama a onDone sin recorrer las diapositivas', (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingPage(onDone: () => done = true),
    ));

    await tester.tap(find.text('Omitir'));
    await tester.pump();
    expect(done, isTrue);
  });
}
