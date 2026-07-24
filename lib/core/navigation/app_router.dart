import 'package:flutter/material.dart';

import '../../features/activities/presentation/pages/activity_types_page.dart';
import '../../features/projects/presentation/pages/projects_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/tasks/presentation/pages/task_detail_page.dart';
import '../../features/tasks/presentation/pages/task_recurrences_page.dart';
import 'app_routes.dart';
import 'lock_gate.dart';

/// Punto unico donde se conocen todas las pantallas de la app.
abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case AppRoutes.projects:
        return MaterialPageRoute(builder: (_) => const ProjectsPage());
      case AppRoutes.activityTypes:
        return MaterialPageRoute(builder: (_) => const ActivityTypesPage());
      case AppRoutes.taskRecurrences:
        return MaterialPageRoute(builder: (_) => const TaskRecurrencesPage());
      case AppRoutes.taskDetail:
        final taskId = settings.arguments! as String;
        return MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: taskId));
      case AppRoutes.root:
      default:
        return MaterialPageRoute(builder: (_) => const LockGate());
    }
  }
}
