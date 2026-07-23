import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/metrics/presentation/bloc/analyze_cubit.dart';
import '../../features/metrics/presentation/pages/analyze_page.dart';
import '../../features/schedule/presentation/bloc/schedule_cubit.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/tasks/presentation/bloc/tasks_list_cubit.dart';
import '../../features/tasks/presentation/pages/tasks_list_page.dart';
import '../../shared/shared.dart';
import '../di/service_locator.dart';
import 'register_sheet.dart';

/// Cascaron de la app: 4 destinos + FAB central de registro.
/// Compone paginas de varias features, por eso vive en core/navigation.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _items = [
    BottomBarItem(icon: AppIcons.today, label: 'Hoy'),
    BottomBarItem(icon: AppIcons.agenda, label: 'Agenda'),
    BottomBarItem(icon: AppIcons.tasks, label: 'Tareas'),
    BottomBarItem(icon: AppIcons.analyze, label: 'Analizar'),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<DashboardCubit>()),
        BlocProvider(create: (_) => sl<ScheduleCubit>()),
        BlocProvider(create: (_) => sl<TasksListCubit>()),
        BlocProvider(create: (_) => sl<AnalyzeCubit>()),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: AppSpacing.page,
            child: IndexedStack(
              index: _index,
              children: const [
                DashboardPage(),
                SchedulePage(),
                TasksListPage(),
                AnalyzePage(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomBar(
          items: _items,
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          onFabPressed: () => showRegisterSheet(context),
        ),
      ),
    );
  }
}
