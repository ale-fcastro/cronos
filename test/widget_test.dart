import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/di/service_locator.dart';
import 'package:cronos/main.dart';

void main() {
  sqfliteFfiInit();

  setUp(() async {
    await GetIt.instance.reset();
    configureDependencies(
      database: AppDatabase(
        factory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      ),
    );
  });

  testWidgets('Cronos arranca y muestra el dashboard Hoy', (tester) async {
    await tester.pumpWidget(const CronosApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Hoy'), findsWidgets);

    // Desmonta el árbol para cerrar cubits y cancelar los tickers.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
