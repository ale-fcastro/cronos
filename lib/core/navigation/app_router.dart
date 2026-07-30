import 'package:flutter/material.dart';

import '../../features/activities/presentation/pages/activity_types_page.dart';
import '../../features/habits/presentation/pages/habits_page.dart';
import '../../features/projects/presentation/pages/projects_page.dart';
import '../../features/settings/presentation/pages/life_areas_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/support_info_page.dart';
import '../../features/tasks/presentation/pages/task_detail_page.dart';
import '../../features/tasks/presentation/pages/task_recurrences_page.dart';
import 'app_page_route.dart';
import 'app_routes.dart';
import 'startup_gate.dart';

/// Punto unico donde se conocen todas las pantallas de la app.
abstract final class AppRouter {
  /// Permite navegar desde fuera del árbol de widgets (p.ej. al tocar una
  /// notificación), sin depender de un BuildContext concreto.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.settings:
        return AppPageRoute(
            builder: (_) => const SettingsPage(), settings: settings);
      case AppRoutes.projects:
        return AppPageRoute(
            builder: (_) => const ProjectsPage(), settings: settings);
      case AppRoutes.activityTypes:
        return AppPageRoute(
            builder: (_) => const ActivityTypesPage(), settings: settings);
      case AppRoutes.taskRecurrences:
        return AppPageRoute(
            builder: (_) => const TaskRecurrencesPage(), settings: settings);
      case AppRoutes.support:
        return AppPageRoute(
            builder: (_) => const SupportInfoPage(), settings: settings);
      case AppRoutes.lifeAreas:
        return AppPageRoute(
            builder: (_) => const LifeAreasPage(), settings: settings);
      case AppRoutes.habits:
        return AppPageRoute(
            builder: (_) => const HabitsPage(), settings: settings);
      case AppRoutes.taskDetail:
        final args = settings.arguments!;
        final taskId = args is TaskDetailArgs ? args.taskId : args as String;
        final askIfDone = args is TaskDetailArgs ? args.askIfDone : false;
        return AppPageRoute(
            builder: (_) => TaskDetailPage(taskId: taskId, askIfDone: askIfDone),
            settings: settings);
      case AppRoutes.root:
      default:
        return AppPageRoute(
            builder: (_) => const StartupGate(), settings: settings);
    }
  }
}
