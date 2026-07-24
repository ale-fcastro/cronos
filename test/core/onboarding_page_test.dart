import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/navigation/onboarding_page.dart';
import 'package:cronos/core/services/notifications_service.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    // "Empezar" pide el permiso de notificaciones: el servicio necesita
    // estar registrado, aunque en este entorno de test degrade a no-op.
    GetIt.instance.registerLazySingleton(() => NotificationsService(database));
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await database.close();
  });

  testWidgets('recorrer las diapositivas con Siguiente llega a Empezar', (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingPage(onDone: () => done = true),
    ));

    expect(find.text('¡Hola! Soy Croni'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);

    // Croni respira/parpadea sin parar (a propósito, para sentirse vivo),
    // así que la animación nunca "se asienta": pumpAndSettle no sirve acá,
    // se avanza con pumps acotados en su lugar.
    // 3 toques en "Siguiente" recorren las 4 diapositivas.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('Empezar'), findsOneWidget);
    await tester.tap(find.text('Empezar'));
    await tester.pump(const Duration(milliseconds: 400));

    // Sin permiso concedido, "Empezar" abre el modal de avisos antes de
    // continuar; lo cerramos con "Ahora no" para terminar el flujo.
    expect(find.text('Avisos de tareas'), findsOneWidget);
    await tester.tap(find.text('Ahora no'));
    await tester.pump(const Duration(milliseconds: 400));
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
