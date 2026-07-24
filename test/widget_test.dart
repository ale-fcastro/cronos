import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/di/service_locator.dart';
import 'package:cronos/core/diagnostics/error_reporting.dart';
import 'package:cronos/main.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;

  setUp(() async {
    await GetIt.instance.reset();
    clearLastError();
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    configureDependencies(database: database);
  });

  tearDown(() => database.close());

  testWidgets('Cronos arranca y el dashboard carga contenido real',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      originalOnError?.call(details);
    };

    await tester.pumpWidget(const CronosApp());

    // runAsync deja que la I/O real de SQLite (fuera del reloj falso del
    // test) complete de verdad; el pump por iteración deja que el árbol
    // se reconstruya con cada emit del cubit.
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (find.text('Eficiencia').evaluate().isNotEmpty) break;
    }

    if (errors.isNotEmpty || lastErrorNotifier.value != null) {
      fail('Error durante el arranque:\n'
          '${errors.map((e) => e.exceptionAsString()).join('\n---\n')}\n'
          'lastErrorNotifier: ${lastErrorNotifier.value}');
    }

    expect(find.text('Hoy'), findsWidgets);
    expect(find.text('Eficiencia'), findsOneWidget);
    expect(find.text('Cumplimiento'), findsOneWidget);

    FlutterError.onError = originalOnError;

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
