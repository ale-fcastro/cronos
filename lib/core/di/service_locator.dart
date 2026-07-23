import 'package:get_it/get_it.dart';

import '../../features/activities/data/datasources/activities_mock_datasource.dart';
import '../../features/activities/data/repositories/activities_repository_impl.dart';
import '../../features/activities/domain/repositories/activities_repository.dart';
import '../../features/activities/domain/usecases/activities_usecases.dart';
import '../../features/activities/presentation/bloc/activities_cubit.dart';

import '../../features/dashboard/data/datasources/dashboard_mock_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_today_summary.dart';
import '../../features/dashboard/presentation/bloc/dashboard_cubit.dart';

import '../../features/events/data/datasources/events_mock_datasource.dart';
import '../../features/events/data/repositories/events_repository_impl.dart';
import '../../features/events/domain/repositories/events_repository.dart';
import '../../features/events/domain/usecases/events_usecases.dart';
import '../../features/events/presentation/bloc/event_register_cubit.dart';

import '../../features/metrics/data/datasources/metrics_mock_datasource.dart';
import '../../features/metrics/data/repositories/metrics_repository_impl.dart';
import '../../features/metrics/domain/repositories/metrics_repository.dart';
import '../../features/metrics/domain/usecases/metrics_usecases.dart';
import '../../features/metrics/presentation/bloc/analyze_cubit.dart';

import '../../features/schedule/data/datasources/schedule_mock_datasource.dart';
import '../../features/schedule/data/repositories/schedule_repository_impl.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';
import '../../features/schedule/domain/usecases/get_day_agenda.dart';
import '../../features/schedule/domain/usecases/get_month_overview.dart';
import '../../features/schedule/presentation/bloc/schedule_cubit.dart';

import '../../features/settings/data/datasources/settings_mock_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/presentation/bloc/settings_cubit.dart';

import '../../features/tasks/data/datasources/tasks_mock_datasource.dart';
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
void configureDependencies() {
  // Dashboard
  sl.registerLazySingleton(() => DashboardMockDatasource());
  sl.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetTodaySummary(sl()));
  sl.registerFactory(() => DashboardCubit(sl()));

  // Schedule
  sl.registerLazySingleton(() => ScheduleMockDatasource());
  sl.registerLazySingleton<ScheduleRepository>(() => ScheduleRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetDayAgenda(sl()));
  sl.registerLazySingleton(() => GetMonthOverview(sl()));
  sl.registerFactory(() => ScheduleCubit(sl(), sl()));

  // Tasks
  sl.registerLazySingleton(() => TasksMockDatasource());
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
  sl.registerLazySingleton(() => ActivitiesMockDatasource());
  sl.registerLazySingleton<ActivitiesRepository>(() => ActivitiesRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetFrequentActivities(sl()));
  sl.registerLazySingleton(() => GetTodayActivityLog(sl()));
  sl.registerLazySingleton(() => GetRunningActivity(sl()));
  sl.registerLazySingleton(() => StartActivity(sl()));
  sl.registerLazySingleton(() => StopRunningActivity(sl()));
  sl.registerFactory(() => ActivitiesCubit(sl(), sl(), sl(), sl(), sl()));

  // Events
  sl.registerLazySingleton(() => EventsMockDatasource());
  sl.registerLazySingleton<EventsRepository>(() => EventsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SearchEventSuggestions(sl()));
  sl.registerLazySingleton(() => RegisterEvent(sl()));
  sl.registerFactory(() => EventRegisterCubit(sl(), sl()));

  // Metrics (Analizar)
  sl.registerLazySingleton(() => MetricsMockDatasource());
  sl.registerLazySingleton<MetricsRepository>(() => MetricsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMetricsSnapshot(sl()));
  sl.registerLazySingleton(() => GetTaskStatistics(sl()));
  sl.registerLazySingleton(() => GetPhoneUsage(sl()));
  sl.registerLazySingleton(() => GetEventsStatistics(sl()));
  sl.registerFactory(() => AnalyzeCubit(sl(), sl(), sl(), sl()));

  // Settings
  sl.registerLazySingleton(() => SettingsMockDatasource());
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerFactory(() => SettingsCubit(sl()));
}
