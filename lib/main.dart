import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/di/service_locator.dart';
import 'core/diagnostics/error_banner.dart';
import 'core/diagnostics/error_reporting.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'core/services/notifications_service.dart';
import 'features/tasks/domain/usecases/task_recurrence_usecases.dart';
import 'shared/theme/app_theme.dart';

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

    final notifications = sl<NotificationsService>();
    try {
      await notifications.initialize();
      notifications.onTaskReminderTapped = (taskId) {
        AppRouter.navigatorKey.currentState
            ?.pushNamed(AppRoutes.taskDetail, arguments: taskId);
      };
    } catch (e, st) {
      reportError('NotificationsService.initialize', e, st);
    }

    runApp(const CronosApp());

    // Si la app estaba cerrada y se abrió tocando un aviso, navega al
    // detalle de esa tarea en cuanto el primer frame esté listo.
    final launchTaskId = await notifications.consumeLaunchPayload();
    if (launchTaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.navigatorKey.currentState
            ?.pushNamed(AppRoutes.taskDetail, arguments: launchTaskId);
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
