import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workmanager/workmanager.dart';

import 'core/analytics/stats_engine.dart';
import 'core/database/app_database.dart';
import 'core/di/service_locator.dart';
import 'core/diagnostics/error_banner.dart';
import 'core/diagnostics/error_reporting.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'core/services/app_update_service.dart';
import 'core/services/app_usage_service.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/notifications_service.dart';
import 'core/services/nudge_service.dart';
import 'core/services/overdue_task_service.dart';
import 'core/services/session_notification_service.dart';
import 'core/services/timer_service.dart';
import 'features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'features/habits/data/datasources/habits_local_datasource.dart';
import 'features/tasks/domain/usecases/task_recurrence_usecases.dart';
import 'shared/shared.dart';

/// Punto de entrada que WorkManager invoca en un isolate aparte cada vez
/// que corre la tarea periódica: no comparte el GetIt del isolate principal,
/// así que arma sus propias instancias mínimas.
@pragma('vm:entry-point')
void nudgeCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == HomeWidgetService.refreshTaskName) {
      try {
        await _refreshHomeWidgetsInBackground();
      } catch (_) {
        // Red de seguridad nomás: el próximo evento de TimerService (o la
        // siguiente corrida de esta misma tarea) va a refrescar igual.
      }
      return true;
    }
    final database = AppDatabase();
    final notifications = NotificationsService(database);
    try {
      final nudge = NudgeService(database, AppUsageService());
      final message = await nudge.checkForNudge();
      if (message != null) {
        await notifications.initialize();
        await notifications.showNow('Croni te avisa', message);
      }
    } catch (_) {
      // Un aviso perdido no es grave; nunca debe tirar la tarea en segundo plano.
    }
    try {
      final overdue = await OverdueTaskService(database).collectNewlyOverdue();
      if (overdue.isNotEmpty) {
        await notifications.initialize();
        for (final (id, title) in overdue) {
          await notifications.showTaskOverdue(id, title);
        }
      }
    } catch (_) {
      // Idem: un aviso de vencimiento perdido no debe tirar la tarea.
    }
    return true;
  });
}

/// Refresca los widgets "Hoy", "Semanal" y "Hábitos" para el rollover de
/// medianoche: el score de "Hoy" cambia con el simple paso del tiempo, sin
/// que el usuario toque nada, así que el disparo event-driven de
/// [HomeWidgetService] no alcanza para eso. No cubre "Sesión" a propósito:
/// ese widget solo cambia con eventos de [TimerService], que ya la
/// mantienen al día en vivo. Arma su propia cadena de dependencias (mismo
/// motivo que [nudgeCallbackDispatcher]: este isolate no comparte el GetIt
/// del principal).
Future<void> _refreshHomeWidgetsInBackground() async {
  final database = AppDatabase();
  final stats = StatsEngine(database);
  final dashboard = DashboardLocalDatasource(database, stats);
  final summary = await dashboard.fetchTodaySummary();

  await HomeWidget.saveWidgetData('today_score', summary.score);
  await HomeWidget.saveWidgetData('today_productive_label', summary.productiveLabel);
  await HomeWidget.saveWidgetData('today_lost_label', summary.lostLabel);
  await HomeWidget.saveWidgetData('today_date_label', summary.dateLabel);
  await HomeWidget.saveWidgetData('today_next_task_title', summary.nextTask?.title ?? '');
  await HomeWidget.saveWidgetData('today_next_task_time', summary.nextTask?.time ?? '');
  await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.example.cronos.widgets.HomeWidgetProvider');

  await HomeWidget.saveWidgetData('weekly_scores',
      summary.weeklyScores.map((p) => p.value.toStringAsFixed(2)).join(','));
  await HomeWidget.saveWidgetData(
      'weekly_labels', summary.weeklyScores.map((p) => p.label).join(','));
  await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.example.cronos.widgets.WeeklyWidgetProvider');

  const maxHabits = 5;
  final habits =
      (await HabitsLocalDatasource(database).fetchHabits()).take(maxHabits).toList();
  await HomeWidget.saveWidgetData('habits_count', habits.length);
  for (var i = 0; i < maxHabits; i++) {
    if (i < habits.length) {
      final item = habits[i];
      await HomeWidget.saveWidgetData('habit_${i}_id', item.habit.id);
      await HomeWidget.saveWidgetData('habit_${i}_title', item.habit.title);
      await HomeWidget.saveWidgetData('habit_${i}_done_today', item.doneToday);
      await HomeWidget.saveWidgetData('habit_${i}_streak', item.streak);
    } else {
      await HomeWidget.saveWidgetData('habit_${i}_title', '');
    }
  }
  await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.example.cronos.widgets.HabitsWidgetProvider');
}

/// Punto de entrada que home_widget invoca en un isolate aparte para
/// acciones de widgets/notificación con la app cerrada (ver
/// SessionForegroundService.kt, SessionWidgetProvider.kt, HabitsWidgetProvider.kt):
/// no comparte el GetIt del isolate principal, así que arma sus propias
/// instancias mínimas, igual que [nudgeCallbackDispatcher]. Solo cubre
/// acciones que no requieren el diálogo de confirmación de tarea (pausar una
/// tarea, finalizar una actividad, tildar un hábito) — finalizar una tarea
/// abre la app en cambio (ver el manejo de 'task-detail' más abajo).
@pragma('vm:entry-point')
Future<void> homeWidgetInteractionCallback(Uri? uri) async {
  if (uri == null) return;
  try {
    if (uri.host == 'session-action') {
      final type = uri.queryParameters['type'];
      final kind = uri.queryParameters['kind'];
      final taskId = uri.queryParameters['taskId'];
      final timer = TimerService(AppDatabase());
      if (type == 'pause' && kind == 'task' && taskId != null) {
        await timer.pauseTask(taskId);
      } else if (type == 'finish' && kind == 'activity') {
        await timer.stopRunningActivity();
      }
    } else if (uri.host == 'habit-toggle') {
      final habitId = uri.queryParameters['habitId'];
      if (habitId != null) {
        final habitsDatasource = HabitsLocalDatasource(AppDatabase());
        await habitsDatasource.toggleToday(habitId);
        // Este isolate no comparte el HomeWidgetService del isolate
        // principal (ni su TimerService.events): empuja el widget de
        // hábitos acá mismo con los datos ya frescos, mismo formato que
        // HomeWidgetService._pushHabits().
        const maxHabits = 5;
        final habits = (await habitsDatasource.fetchHabits()).take(maxHabits).toList();
        await HomeWidget.saveWidgetData('habits_count', habits.length);
        for (var i = 0; i < maxHabits; i++) {
          if (i < habits.length) {
            final item = habits[i];
            await HomeWidget.saveWidgetData('habit_${i}_id', item.habit.id);
            await HomeWidget.saveWidgetData('habit_${i}_title', item.habit.title);
            await HomeWidget.saveWidgetData('habit_${i}_done_today', item.doneToday);
            await HomeWidget.saveWidgetData('habit_${i}_streak', item.streak);
          } else {
            await HomeWidget.saveWidgetData('habit_${i}_title', '');
          }
        }
        await HomeWidget.updateWidget(
          qualifiedAndroidName: 'com.example.cronos.widgets.HabitsWidgetProvider',
        );
      }
    }
  } catch (_) {
    // La notificación/foreground service ya se cerraron nativamente pase lo
    // que pase acá (ver SessionForegroundService.kt): una mutación perdida
    // no debe dejar nada colgado, la próxima apertura de la app refleja el
    // estado real de la base igual.
  }
}

void main() {
  // Cualquier excepción (incluida la de abrir la base de datos) se reporta
  // via [reportError] -> se ve como banner rojo en la app, en vez de quedar
  // silenciada dentro de un Future no esperado. Una pantalla en blanco sin
  // rastro visible es lo peor que le puede pasar a esta app en desarrollo.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
      reportError('Build', details.exception, details.stack ?? StackTrace.empty);
    };

    // En escritorio (Linux/Windows) sqflite no existe: usamos SQLite via FFI.
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    configureDependencies();

    // Materializa las ocurrencias pendientes de tareas recurrentes antes del
    // primer frame, para que Hoy/Agenda ya las muestren.
    try {
      await sl<GenerateRecurringTasks>()();
    } catch (e, st) {
      reportError('GenerateRecurringTasks', e, st);
    }

    // Los widgets de home screen y la notificación persistente de sesión son
    // exclusivos de Android: no hay equivalente en escritorio y todavía no
    // se implementó el lado iOS.
    if (Platform.isAndroid) {
      try {
        await sl<HomeWidgetService>().start();
      } catch (e, st) {
        reportError('HomeWidgetService.start', e, st);
      }
      try {
        await sl<SessionNotificationService>().start();
      } catch (e, st) {
        reportError('SessionNotificationService.start', e, st);
      }
      try {
        await HomeWidget.registerInteractivityCallback(homeWidgetInteractionCallback);
      } catch (e, st) {
        reportError('HomeWidget.registerInteractivityCallback', e, st);
      }
    }

    // WorkManager solo existe en Android/iOS; en escritorio no hay
    // background scheduling real, así que los avisos de uso y de tareas
    // vencidas quedan ausentes ahí sin romper nada más.
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await Workmanager().initialize(nudgeCallbackDispatcher);
        // La tarea periódica hace dos chequeos independientes (distracción
        // y tareas vencidas); se registra si cualquiera de los dos puede
        // tener algo que avisar — cada chequeo respeta su propio apagado
        // adentro del dispatcher.
        final nudgeEnabled = await sl<NudgeService>().isEnabled();
        final notificationsEnabled = await sl<NotificationsService>().isEnabled();
        if (nudgeEnabled || notificationsEnabled) {
          await Workmanager().registerPeriodicTask(
            NudgeService.taskName,
            NudgeService.taskName,
            frequency: const Duration(minutes: 15),
          );
        }
        // Red de seguridad para el rollover de medianoche de los widgets
        // "Hoy"/"Semanal"/"Hábitos" (ver _refreshHomeWidgetsInBackground).
        // Solo Android: son los únicos widgets de home screen que existen.
        if (Platform.isAndroid) {
          await Workmanager().registerPeriodicTask(
            HomeWidgetService.refreshTaskName,
            HomeWidgetService.refreshTaskName,
            frequency: const Duration(minutes: 20),
          );
        }
      } catch (e, st) {
        reportError('Workmanager.initialize', e, st);
      }
    }

    final notifications = sl<NotificationsService>();
    try {
      await notifications.initialize();
      notifications.onTaskReminderTapped = (taskId) {
        AppRouter.navigatorKey.currentState
            ?.pushNamed(AppRoutes.taskDetail, arguments: taskId);
      };
      notifications.onTaskOverdueTapped = (taskId) {
        AppRouter.navigatorKey.currentState?.pushNamed(
          AppRoutes.taskDetail,
          arguments: TaskDetailArgs(taskId, askIfDone: true),
        );
      };
      // Si tocás el aviso de actualización con la app ya abierta (no
      // relanzada), el startup check de RootShell no vuelve a correr:
      // sin esto, no pasaba nada hasta cerrar del todo y reabrir.
      notifications.onUpdateNotificationTapped = () async {
        final update = await sl<AppUpdateService>().checkForUpdate();
        final ctx = AppRouter.navigatorKey.currentContext;
        if (update == null || ctx == null) return;
        // navigatorKey es global y vive con la app entera: no hay un
        // "mounted" de State que chequear acá.
        // ignore: use_build_context_synchronously
        await showUpdateAvailableDialog(ctx, update);
      };
    } catch (e, st) {
      reportError('NotificationsService.initialize', e, st);
    }

    runApp(const CronosApp());

    // Si la app estaba cerrada y se abrió tocando un aviso de tarea, navega
    // a su detalle en cuanto el primer frame esté listo. El aviso de
    // actualización no necesita este camino: el chequeo normal de arranque
    // (RootShell) ya corre solo y muestra el diálogo si sigue vigente.
    final launchPayload = await notifications.consumeLaunchPayload();
    if (launchPayload != null && launchPayload != NotificationsService.updatePayload) {
      final isOverdue = launchPayload.startsWith(NotificationsService.overduePayloadPrefix);
      final taskId = isOverdue
          ? launchPayload.substring(NotificationsService.overduePayloadPrefix.length)
          : launchPayload;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.navigatorKey.currentState?.pushNamed(
          AppRoutes.taskDetail,
          arguments: TaskDetailArgs(taskId, askIfDone: isOverdue),
        );
      });
    }

    // Dos casos abren la app vía el mecanismo de lanzamiento de home_widget
    // (reusado como simple transporte de un Uri al abrir MainActivity, no
    // necesariamente desde un widget de home screen):
    // - Widget "Hoy" > "+ Registrar": trae la app al frente en el dashboard.
    // - Notificación de sesión > "Finalizar" (solo tareas, ver
    //   SessionForegroundService.kt): abre el detalle con el diálogo de
    //   completar — finalizar una tarea nunca es un toque directo en background.
    void handleHomeWidgetLaunchUri(Uri? uri) {
      if (uri == null) return;
      if (uri.host == 'quick-register') {
        AppRouter.navigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else if (uri.host == 'task-detail') {
        final taskId = uri.queryParameters['taskId'];
        if (taskId == null) return;
        AppRouter.navigatorKey.currentState?.pushNamed(
          AppRoutes.taskDetail,
          arguments: TaskDetailArgs(taskId, askIfDone: true),
        );
      }
    }

    if (Platform.isAndroid) {
      try {
        final coldStartUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
        WidgetsBinding.instance
            .addPostFrameCallback((_) => handleHomeWidgetLaunchUri(coldStartUri));
      } catch (e, st) {
        reportError('HomeWidget.initiallyLaunchedFromHomeWidget', e, st);
      }
      HomeWidget.widgetClicked.listen(handleHomeWidgetLaunchUri);
    }
  }, (error, stack) => reportError('Zona no capturada', error, stack));
}

/// Raiz de la app.
class CronosApp extends StatelessWidget {
  const CronosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cronos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      navigatorKey: AppRouter.navigatorKey,
      initialRoute: AppRoutes.root,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) => Stack(
        children: [
          if (child != null) child,
          const ErrorBanner(),
        ],
      ),
    );
  }
}
