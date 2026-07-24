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

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _index = 0;

  late final DashboardCubit _dashboard = sl<DashboardCubit>();
  late final ScheduleCubit _schedule = sl<ScheduleCubit>();
  late final TasksListCubit _tasks = sl<TasksListCubit>();
  late final AnalyzeCubit _analyze = sl<AnalyzeCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dashboard.close();
    _schedule.close();
    _tasks.close();
    _analyze.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cubre, entre otras cosas, volver de Configuración del sistema tras
    // conceder el permiso de "Acceso al uso": al reanudar, Analizar >
    // Teléfono debe reflejar el permiso ya concedido sin que el usuario
    // tenga que hacer nada más.
    if (state == AppLifecycleState.resumed) _refreshAll();
  }

  void _refreshAll() {
    _dashboard.load();
    _schedule.reload();
    _tasks.load();
    _analyze.refresh();
  }

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
        BlocProvider.value(value: _dashboard),
        BlocProvider.value(value: _schedule),
        BlocProvider.value(value: _tasks),
        BlocProvider.value(value: _analyze),
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
          onTap: (i) {
            setState(() => _index = i);
            _refreshAll();
          },
          onFabPressed: () async {
            await showRegisterSheet(context);
            _refreshAll();
          },
        ),
      ),
    );
  }
}
