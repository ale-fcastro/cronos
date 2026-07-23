import 'package:flutter/material.dart';

import 'core/di/service_locator.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/app_routes.dart';
import 'shared/theme/app_theme.dart';

void main() {
  configureDependencies();
  runApp(const CronosApp());
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
      initialRoute: AppRoutes.root,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
