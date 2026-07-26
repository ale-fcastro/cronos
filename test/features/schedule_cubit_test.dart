import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cronos/core/analytics/stats_engine.dart';
import 'package:cronos/core/database/app_database.dart';
import 'package:cronos/core/services/life_areas_service.dart';
import 'package:cronos/core/services/timer_service.dart';
import 'package:cronos/features/schedule/data/datasources/schedule_local_datasource.dart';
import 'package:cronos/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:cronos/features/schedule/domain/usecases/get_day_agenda.dart';
import 'package:cronos/features/schedule/domain/usecases/get_month_overview.dart';
import 'package:cronos/features/schedule/presentation/bloc/schedule_cubit.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late ScheduleCubit cubit;

  setUp(() async {
    database = AppDatabase(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    final datasource = ScheduleLocalDatasource(database, StatsEngine(database));
    final repo = ScheduleRepositoryImpl(datasource);
    cubit = ScheduleCubit(
      GetDayAgenda(repo),
      GetMonthOverview(repo),
      TimerService(database),
      LifeAreasService(database),
    );
    // Deja que termine la carga inicial del constructor.
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  test('previousMonth/nextMonth navegan el calendario', () async {
    final now = DateTime.now();
    final startMonth = cubit.state.month!.referenceMonth;
    expect(startMonth, DateTime(now.year, now.month, 1));

    await cubit.previousMonth();
    final expectedPrev = DateTime(now.year, now.month - 1, 1);
    expect(cubit.state.month!.referenceMonth, expectedPrev);

    await cubit.nextMonth();
    expect(cubit.state.month!.referenceMonth, startMonth);
  });

  test('recargar (reload) no pisa la navegación de mes del usuario', () async {
    await cubit.previousMonth();
    final navigated = cubit.state.month!.referenceMonth;

    // reload() es lo que dispara el ticker y las acciones de start/pause:
    // no debería devolver la vista Mes al mes actual sin que el usuario lo pida.
    await cubit.reload();

    expect(cubit.state.month!.referenceMonth, navigated);
  });
}
