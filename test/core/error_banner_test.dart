import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cronos/core/diagnostics/error_banner.dart';
import 'package:cronos/core/diagnostics/error_reporting.dart';

/// Reproduce la estructura real de CronosApp: ErrorBanner vive en
/// `MaterialApp.builder`, hermano de la app (fuera del Overlay que crea el
/// Navigator interno). Un IconButton con `tooltip:` ahí tira la app entera
/// (RawTooltip exige un Overlay que no está disponible en esa posición).
Widget _appLike(Widget home) {
  return MaterialApp(
    home: home,
    builder: (context, child) => Stack(
      children: [if (child != null) child, const ErrorBanner()],
    ),
  );
}

void main() {
  setUp(clearLastError);
  tearDown(clearLastError);

  testWidgets('el banner con un error se puede pintar sin un Overlay ahí', (tester) async {
    await tester.pumpWidget(_appLike(const Scaffold(body: SizedBox())));

    reportError('test', Exception('boom'), StackTrace.empty);
    await tester.pump();

    expect(find.textContaining('boom'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('copiar y cerrar no requieren un Overlay', (tester) async {
    await tester.pumpWidget(_appLike(const Scaffold(body: SizedBox())));
    reportError('test', Exception('boom'), StackTrace.empty);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('boom'), findsNothing);
  });

  testWidgets('reportar un error durante el build no lo tira por setState-en-build',
      (tester) async {
    // Simula un error de framework (p.ej. de otro widget) reportado
    // mientras este widget todavía se está construyendo -- exactamente lo
    // que pasó cuando el share_plus de Linux tiró y el propio ErrorBanner
    // no pudo pintarse, generando un segundo reporte a mitad de frame.
    await tester.pumpWidget(_appLike(Builder(builder: (context) {
      reportError('mid-build', Exception('boom-en-build'), StackTrace.empty);
      return const Scaffold(body: SizedBox());
    })));

    expect(tester.takeException(), isNull);

    await tester.pump();
    expect(find.textContaining('boom-en-build'), findsOneWidget);
  });
}
