import 'package:get_it/get_it.dart';

import '../analytics/stats_engine.dart';
import '../database/app_database.dart';

import '../../features/activities/data/datasources/activities_local_datasource.dart';
import '../../features/activities/data/repositories/activities_repository_impl.dart';
import '../../features/activities/domain/repositories/activities_repository.dart';
import '../../features/activities/domain/usecases/activities_usecases.dart';
import '../../features/activities/presentation/bloc/activities_cubit.dart';

import '../../features/dashboard/data/datasources/dashboard_local_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_today_summary.dart';
import '../../features/dashboard/presentation/bloc/dashboard_cubit.dart';

import '../../features/events/data/datasources/events_local_datasource.dart';
import '../../features/events/data/repositories/events_repository_impl.dart';
import '../../features/events/domain/repositories/events_repository.dart';
import '../../features/events/domain/usecases/events_usecases.dart';
import '../../features/events/presentation/bloc/event_register_cubit.dart';

import '../../features/metrics/data/datasources/metrics_local_datasource.dart';
import '../../features/metrics/data/repositories/metrics_repository_impl.dart';
import '../../features/metrics/domain/repositories/metrics_repository.dart';
import '../../features/metrics/domain/usecases/metrics_usecases.dart';
import '../../features/metrics/presentation/bloc/analyze_cubit.dart';

import '../../features/schedule/data/datasources/schedule_local_datasource.dart';
import '../../features/schedule/data/repositories/schedule_repository_impl.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../../features/schedule/domain/usecases/get_day_agenda.dart';
import '../../features/schedule/domain/usecases/get_month_overview.dart';
import '../../features/schedule/presentation/bloc/schedule_cubit.dart';

import '../../features/security/data/datasources/security_local_datasource.dart';
import '../../features/security/data/repositories/security_repository_impl.dart';
import '../../features/security/domain/repositories/security_repository.dart';
import '../../features/security/domain/usecases/security_usecases.dart';
import '../../features/security/presentation/bloc/app_lock_cubit.dart';
import '../../features/security/presentation/bloc/lock_cubit.dart';

import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/presentation/bloc/settings_cubit.dart';

import '../../features/tasks/data/datasources/tasks_local_datasource.dart';
import '../../features/tasks/data/repositories/tasks_repository_impl.dart';
import '../../features/tasks/domain/repositories/tasks_repository.dart';
import '../../features/tasks/domain/usecases/create_task.dart';
import '../../features/tasks/domain/usecases/get_task_detail.dart';
import '../../features/tasks/domain/usecases/get_tasks.dart';
import '../../features/tasks/domain/usecases/task_timer_actions.dart';
import '../../features/tasks/presentation/bloc/create_task_cubit.dart';
import '../../features/tasks/presentation/bloc/task_detail_cubit.dart';
import '../../features/tasks/presentation/bloc/tasks_list_cubit.dart';

final sl = GetIt.instance;

/// Registra datasources, repositorios, casos de uso y cubits.
/// Un feature nunca resuelve dependencias de otro feature directamente:
/// todo pasa por este contenedor.
///
/// [database] permite inyectar una base en memoria en tests.
void configureDependencies({AppDatabase? database}) {
  // Núcleo
  sl.registerLazySingleton<AppDatabase>(() => database ?? AppDatabase());
  sl.registerLazySingleton(() => StatsEngine(sl()));

  // Dashboard
  sl.registerLazySingleton(() => DashboardLocalDatasource(sl(), sl()));
  sl.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetTodaySummary(sl()));
  sl.registerFactory(() => DashboardCubit(sl()));

  // Schedule
  sl.registerLazySingleton(() => ScheduleLocalDatasource(sl(), sl()));
  sl.registerLazySingleton<ScheduleRepository>(() => ScheduleRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetDayAgenda(sl()));
  sl.registerLazySingleton(() => GetMonthOverview(sl()));
  sl.registerFactory(() => ScheduleCubit(sl(), sl()));

  // Tasks
  sl.registerLazySingleton(() => TasksLocalDatasource(sl()));
  sl.registerLazySingleton<TasksRepository>(() => TasksRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetTasks(sl()));
  sl.registerLazySingleton(() => GetTaskDetail(sl()));
  sl.registerLazySingleton(() => StartTaskTimer(sl()));
  sl.registerLazySingleton(() => PauseTaskTimer(sl()));
  sl.registerLazySingleton(() => CompleteTask(sl()));
  sl.registerLazySingleton(() => CreateTask(sl()));
  sl.registerFactory(() => TasksListCubit(sl(), sl(), sl()));
  sl.registerFactoryParam<TaskDetailCubit, String, void>(
      (taskId, _) => TaskDetailCubit(sl(), sl(), sl(), sl(), taskId));
  sl.registerFactory(() => CreateTaskCubit(sl()));

  // Activities
  sl.registerLazySingleton(() => ActivitiesLocalDatasource(sl()));
  sl.registerLazySingleton<ActivitiesRepository>(() => ActivitiesRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetFrequentActivities(sl()));
  sl.registerLazySingleton(() => GetTodayActivityLog(sl()));
  sl.registerLazySingleton(() => GetRunningActivity(sl()));
  sl.registerLazySingleton(() => StartActivity(sl()));
  sl.registerLazySingleton(() => StopRunningActivity(sl()));
  sl.registerFactory(() => ActivitiesCubit(sl(), sl(), sl(), sl(), sl()));

  // Events
  sl.registerLazySingleton(() => EventsLocalDatasource(sl()));
  sl.registerLazySingleton<EventsRepository>(() => EventsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SearchEventSuggestions(sl()));
  sl.registerLazySingleton(() => RegisterEvent(sl()));
  sl.registerFactory(() => EventRegisterCubit(sl(), sl()));

  // Metrics (Analizar)
  sl.registerLazySingleton(() => MetricsLocalDatasource(sl(), sl()));
  sl.registerLazySingleton<MetricsRepository>(() => MetricsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMetricsSnapshot(sl()));
  sl.registerLazySingleton(() => GetTaskStatistics(sl()));
  sl.registerLazySingleton(() => GetPhoneUsage(sl()));
  sl.registerLazySingleton(() => GetEventsStatistics(sl()));
  sl.registerFactory(() => AnalyzeCubit(sl(), sl(), sl(), sl()));

  // Security
  sl.registerLazySingleton(() => SecurityLocalDatasource(sl()));
  sl.registerLazySingleton<SecurityRepository>(() => SecurityRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetLockEnabled(sl()));
  sl.registerLazySingleton(() => SetLockEnabled(sl()));
  sl.registerLazySingleton(() => CanAuthenticate(sl()));
  sl.registerLazySingleton(() => Authenticate(sl()));
  sl.registerFactory(() => LockCubit(sl(), sl(), sl()));
  sl.registerFactory(() => AppLockCubit(sl(), sl(), sl(), sl()));

  // Settings
  sl.registerLazySingleton(() => SettingsLocalDatasource(sl()));
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerFactory(() => SettingsCubit(sl()));
}
