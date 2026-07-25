import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

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
import '../models/event_category.dart';
import '../services/app_update_service.dart';
import '../services/life_areas_service.dart';
import '../services/linked_app_guard_service.dart';
import '../services/notifications_service.dart';
import '../services/onboarding_service.dart';
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
  late final OnboardingService _onboarding = sl<OnboardingService>();
  late final LinkedAppGuardService _linkedAppGuard = sl<LinkedAppGuardService>();
  late final AppUpdateService _appUpdate = sl<AppUpdateService>();
  late final NotificationsService _notifications = sl<NotificationsService>();

  final _fabKey = GlobalKey();
  final _analyzeKey = GlobalKey();
  final _avatarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ShowcaseView.register(
      onFinish: () => _onboarding.markTourSeen(),
      onDismiss: (_) => _onboarding.markTourSeen(),
      blurValue: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCheckUpdate());
  }

  Future<void> _maybeStartTour() async {
    if (await _onboarding.hasSeenTour()) return;
    if (!mounted) return;
    ShowcaseView.get().startShowCase([_fabKey, _analyzeKey, _avatarKey]);
  }

  /// Chequea GitHub Releases al abrir la app; si hay una versión más nueva,
  /// ofrece descargarla. Silencioso ante cualquier falla (sin red, repo
  /// privado, rate limit): nunca debe interrumpir el arranque normal.
  Future<void> _maybeCheckUpdate() async {
    final update = await _appUpdate.checkForUpdate();
    if (update == null) return;
    unawaited(_notifications.showUpdateAvailable(update.version));
    if (!mounted) return;
    await showUpdateAvailableDialog(context, update);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ShowcaseView.get().unregister();
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
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
      _maybeGuardLinkedApp();
    }
  }

  void _refreshAll() {
    _dashboard.load();
    _schedule.reload();
    _tasks.load();
    _analyze.refresh();
  }

  /// Si Cronos vuelve al frente mientras corre una tarea vinculada a una
  /// app y se detecta que esa app fue abandonada por otra cosa, la
  /// auto-pausa y pide justificación (con "fue sin querer" como opción para
  /// descartarla y retomar con otros 5 segundos de gracia). Android no deja
  /// que una app en segundo plano se traiga a sí misma al frente, así que
  /// esto solo puede dispararse cuando el usuario ya volvió por su cuenta.
  Future<void> _maybeGuardLinkedApp() async {
    final running = await _linkedAppGuard.getRunningLinkedTask();
    if (running == null) return;
    final left = await _linkedAppGuard.didLeave(running.packageName);
    if (!left || !mounted) return;

    await _linkedAppGuard.autoPauseForLeave(running.id);
    _refreshAll();
    if (!mounted) return;

    final areas = await sl<LifeAreasService>().getAll();
    if (!mounted) return;
    final result = await PauseReasonDialog.show(
      context,
      reasons: [...eventCategories, 'Fue sin querer'],
      areas: areas,
    );
    if (result == null) return;

    if (result.reason == 'Fue sin querer') {
      await _linkedAppGuard.discardAndResume(running.id);
      _refreshAll();
      if (!mounted) return;
      final reopened = await OpenLinkedAppDialog.show(
        context,
        packageName: running.packageName,
        appName: running.appName,
      );
      if (!reopened) {
        await _linkedAppGuard.autoPauseForLeave(running.id);
        _refreshAll();
      }
    } else {
      await _linkedAppGuard.confirmJustification(running.id,
          reason: result.reason, areaId: result.areaId);
      _refreshAll();
    }
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
              children: [
                DashboardPage(avatarKey: _avatarKey),
                const SchedulePage(),
                const TasksListPage(),
                const AnalyzePage(),
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
          wrapFab: (fab) => Showcase(
            key: _fabKey,
            title: 'Dale, tocá acá',
            description: 'Con este botón te registro una tarea, una '
                'actividad o un imprevisto en 2 toques. Probalo cuando '
                'quieras.',
            targetShapeBorder: const CircleBorder(),
            child: fab,
          ),
          wrapItem: (i, child) => i == 3
              ? Showcase(
                  key: _analyzeKey,
                  title: 'Tus números están acá',
                  description: 'Métricas, tareas, uso del teléfono y '
                      'eventos: todo junto para que veas cómo te está '
                      'yendo de verdad.',
                  child: child,
                )
              : child,
        ),
      ),
    );
  }
}
