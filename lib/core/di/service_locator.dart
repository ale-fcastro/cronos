import 'package:get_it/get_it.dart';

import '../analytics/stats_engine.dart';
import '../database/app_database.dart';
import '../services/app_update_service.dart';
import '../services/app_usage_service.dart';
import '../services/calendar_import_service.dart';
import '../services/export_service.dart';
import '../services/home_widget_service.dart';
import '../services/life_areas_service.dart';
import '../services/linked_app_guard_service.dart';
import '../services/notifications_service.dart';
import '../services/nudge_service.dart';
import '../services/onboarding_service.dart';
import '../services/profile_service.dart';
import '../services/projects_service.dart';
import '../services/session_notification_service.dart';
import '../services/timer_service.dart';

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

import '../../features/habits/data/datasources/habits_local_datasource.dart';
import '../../features/habits/data/repositories/habits_repository_impl.dart';
import '../../features/habits/domain/repositories/habits_repository.dart';
import '../../features/habits/domain/usecases/habits_usecases.dart';
import '../../features/habits/presentation/bloc/habits_cubit.dart';

import '../../features/events/data/datasources/events_local_datasource.dart';
import '../../features/events/data/repositories/events_repository_impl.dart';
import '../../features/events/domain/repositories/events_repository.dart';
import '../../features/events/domain/usecases/events_usecases.dart';
import '../../features/events/presentation/bloc/event_register_cubit.dart';

import '../../features/metrics/data/datasources/metrics_local_datasource.dart';
import '../../features/metrics/data/repositories/metrics_repository_impl.dart';
import '../../features/metrics/domain/repositories/metrics_repository.dart';
import '../../features/metrics/domain/services/ai_summary_service.dart';
import '../../features/metrics/domain/usecases/metrics_usecases.dart';
import '../../features/metrics/presentation/bloc/analyze_cubit.dart';

import '../../features/notifications/data/datasources/notifications_local_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/notifications_usecases.dart';
import '../../features/notifications/presentation/bloc/notifications_settings_cubit.dart';

import '../../features/projects/data/datasources/projects_local_datasource.dart';
import '../../features/projects/data/repositories/projects_repository_impl.dart';
import '../../features/projects/domain/repositories/projects_repository.dart';
import '../../features/projects/domain/usecases/projects_usecases.dart';
import '../../features/projects/presentation/bloc/projects_cubit.dart';

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
import '../../features/settings/domain/usecases/custom_schedule_usecases.dart';
import '../../features/settings/domain/usecases/schedule_range_usecases.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/domain/usecases/update_setting.dart';
import '../../features/settings/presentation/bloc/life_areas_cubit.dart';
import '../../features/settings/presentation/bloc/settings_cubit.dart';

import '../../features/tasks/data/datasources/tasks_local_datasource.dart';
import '../../features/tasks/data/repositories/tasks_repository_impl.dart';
import '../../features/tasks/domain/repositories/tasks_repository.dart';
import '../../features/tasks/domain/usecases/create_task.dart';
import '../../features/tasks/domain/usecases/delete_task.dart';
import '../../features/tasks/domain/usecases/edit_task.dart';
import '../../features/tasks/domain/usecases/get_task_detail.dart';
import '../../features/tasks/domain/usecases/get_tasks.dart';
import '../../features/tasks/domain/usecases/search_task_suggestions.dart';
import '../../features/tasks/domain/usecases/task_recurrence_usecases.dart';
import '../../features/tasks/domain/usecases/task_timer_actions.dart';
import '../../features/tasks/presentation/bloc/create_task_cubit.dart';
import '../../features/tasks/presentation/bloc/task_detail_cubit.dart';
import '../../features/tasks/presentation/bloc/tasks_list_cubit.dart';
import '../../features/tasks/presentation/bloc/task_recurrences_cubit.dart';

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
  sl.registerLazySingleton(() => LifeAreasService(sl()));
  sl.registerLazySingleton(() => ProjectsService(sl()));
  sl.registerLazySingleton(() => TimerService(sl()));
  sl.registerLazySingleton(() => AppUsageService());
  sl.registerLazySingleton(() => AppUpdateService(sl()));
  sl.registerLazySingleton(() => CalendarImportService(sl()));
  sl.registerLazySingleton(() => LinkedAppGuardService(sl(), sl(), sl()));
  sl.registerLazySingleton(() => ExportService(sl()));
  sl.registerLazySingleton(() => NudgeService(sl(), sl()));
  sl.registerLazySingleton(() => NotificationsService(sl()));
  sl.registerLazySingleton(() => OnboardingService(sl()));
  sl.registerLazySingleton(() => ProfileService(sl()));

  // Dashboard
  sl.registerLazySingleton(() => DashboardLocalDatasource(sl(), sl()));
  sl.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetTodaySummary(sl()));
  sl.registerFactory(() => DashboardCubit(sl(), sl(), sl()));
  sl.registerLazySingleton(() => HomeWidgetService(sl(), sl(), sl()));
  sl.registerLazySingleton(() => SessionNotificationService(sl(), sl(), sl()));

  // Schedule
  sl.registerLazySingleton(() => ScheduleLocalDatasource(sl(), sl()));
  sl.registerLazySingleton<ScheduleRepository>(() => ScheduleRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetDayAgenda(sl()));
  sl.registerLazySingleton(() => GetMonthOverview(sl()));
  sl.registerFactory(() => ScheduleCubit(sl(), sl(), sl(), sl()));

  // Tasks
  sl.registerLazySingleton(() => TasksLocalDatasource(sl(), sl(), sl(), sl()));
  sl.registerLazySingleton<TasksRepository>(() => TasksRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetTasks(sl()));
  sl.registerLazySingleton(() => GetTaskDetail(sl()));
  sl.registerLazySingleton(() => StartTaskTimer(sl()));
  sl.registerLazySingleton(() => PauseTaskTimer(sl()));
  sl.registerLazySingleton(() => CompleteTask(sl()));
  sl.registerLazySingleton(() => MarkTaskNotDone(sl()));
  sl.registerLazySingleton(() => AddSubtask(sl()));
  sl.registerLazySingleton(() => UpdateSubtask(sl()));
  sl.registerLazySingleton(() => ToggleSubtask(sl()));
  sl.registerLazySingleton(() => DeleteSubtask(sl()));
  sl.registerLazySingleton(() => CreateTask(sl()));
  sl.registerLazySingleton(() => GetTaskEditData(sl()));
  sl.registerLazySingleton(() => UpdateTask(sl()));
  sl.registerLazySingleton(() => DeleteTask(sl()));
  sl.registerLazySingleton(() => SearchTaskSuggestions(sl()));
  sl.registerLazySingleton(() => GetTaskRecurrences(sl()));
  sl.registerLazySingleton(() => CreateTaskRecurrence(sl()));
  sl.registerLazySingleton(() => DeleteTaskRecurrence(sl()));
  sl.registerLazySingleton(() => GenerateRecurringTasks(sl()));
  sl.registerLazySingleton(() => CheckScheduleConflict(sl()));
  sl.registerLazySingleton(() => UpdateTaskRecurrenceTime(sl()));
  sl.registerFactory(() => TasksListCubit(sl(), sl(), sl()));
  sl.registerFactoryParam<TaskDetailCubit, String, void>((taskId, _) => TaskDetailCubit(
      sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl(), taskId));
  sl.registerFactoryParam<CreateTaskCubit, String?, void>(
      (editingTaskId, _) => CreateTaskCubit(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl(),
          sl(), sl(), editingTaskId));
  sl.registerFactory(() => TaskRecurrencesCubit(sl(), sl(), sl()));

  // Activities
  sl.registerLazySingleton(() => ActivitiesLocalDatasource(sl(), sl()));
  sl.registerLazySingleton<ActivitiesRepository>(() => ActivitiesRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetFrequentActivities(sl()));
  sl.registerLazySingleton(() => GetTodayActivityLog(sl()));
  sl.registerLazySingleton(() => GetRunningActivity(sl()));
  sl.registerLazySingleton(() => StartActivity(sl()));
  sl.registerLazySingleton(() => StopRunningActivity(sl()));
  sl.registerLazySingleton(() => CreateActivityType(sl()));
  sl.registerLazySingleton(() => UpdateActivityType(sl()));
  sl.registerLazySingleton(() => DeleteActivityType(sl()));
  sl.registerFactory(
      () => ActivitiesCubit(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl()));

  // Events
  sl.registerLazySingleton(() => EventsLocalDatasource(sl()));
  sl.registerLazySingleton<EventsRepository>(() => EventsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SearchEventSuggestions(sl()));
  sl.registerLazySingleton(() => RegisterEvent(sl()));
  sl.registerFactory(() => EventRegisterCubit(sl(), sl(), sl()));

  // Hábitos
  sl.registerLazySingleton(() => HabitsLocalDatasource(sl()));
  sl.registerLazySingleton<HabitsRepository>(() => HabitsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetHabits(sl()));
  sl.registerLazySingleton(() => CreateHabit(sl()));
  sl.registerLazySingleton(() => ArchiveHabit(sl()));
  sl.registerLazySingleton(() => ToggleHabitToday(sl()));
  sl.registerFactory(() => HabitsCubit(sl(), sl(), sl(), sl(), sl()));

  // Notifications
  sl.registerLazySingleton(() => NotificationsLocalDatasource(sl()));
  sl.registerLazySingleton<NotificationsRepository>(() => NotificationsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetNotificationsEnabled(sl()));
  sl.registerLazySingleton(() => SetNotificationsEnabled(sl()));
  sl.registerLazySingleton(() => HasNotificationsPermission(sl()));
  sl.registerLazySingleton(() => RequestNotificationsPermission(sl()));
  sl.registerFactory(() => NotificationsSettingsCubit(sl(), sl(), sl(), sl()));

  // Metrics (Analizar)
  sl.registerLazySingleton(() => MetricsLocalDatasource(sl(), sl(), sl()));
  sl.registerLazySingleton<MetricsRepository>(() => MetricsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMetricsSnapshot(sl()));
  sl.registerLazySingleton(() => GetTaskStatistics(sl()));
  sl.registerLazySingleton(() => GetPhoneUsage(sl()));
  sl.registerLazySingleton(() => GetEventsStatistics(sl()));
  sl.registerLazySingleton(() => AiSummaryService(sl(), sl(), sl(), sl()));
  sl.registerFactory(() => AnalyzeCubit(sl(), sl(), sl(), sl()));

  // Projects
  sl.registerLazySingleton(() => ProjectsLocalDatasource(sl()));
  sl.registerLazySingleton<ProjectsRepository>(() => ProjectsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetProjects(sl()));
  sl.registerLazySingleton(() => CreateProject(sl()));
  sl.registerLazySingleton(() => DeleteProject(sl()));
  sl.registerFactory(() => ProjectsCubit(sl(), sl(), sl()));

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
  sl.registerLazySingleton(() => UpdateSetting(sl()));
  sl.registerLazySingleton(() => CreateCustomSchedule(sl()));
  sl.registerLazySingleton(() => UpdateCustomSchedule(sl()));
  sl.registerLazySingleton(() => DeleteCustomSchedule(sl()));
  sl.registerLazySingleton(() => UpdateScheduleRange(sl()));
  sl.registerLazySingleton(() => DeleteScheduleRange(sl()));
  sl.registerFactory(() => SettingsCubit(sl(), sl(), sl(), sl(), sl(), sl(), sl()));
  sl.registerFactory(() => LifeAreasCubit(sl()));
}
