import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workmanager/workmanager.dart';

import 'core/database/app_database.dart';
import 'core/di/service_locator.dart';
import 'core/diagnostics/error_banner.dart';
import 'core/diagnostics/error_reporting.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'core/services/app_update_service.dart';
import 'core/services/app_usage_service.dart';
import 'core/services/notifications_service.dart';
import 'core/services/nudge_service.dart';
import 'core/services/overdue_task_service.dart';
import 'features/tasks/domain/usecases/task_recurrence_usecases.dart';
import 'shared/shared.dart';

/// Punto de entrada que WorkManager invoca en un isolate aparte cada vez
/// que corre la tarea periódica: no comparte el GetIt del isolate principal,
/// así que arma sus propias instancias mínimas.
@pragma('vm:entry-point')
void nudgeCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
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
