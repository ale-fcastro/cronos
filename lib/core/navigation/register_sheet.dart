import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/activities/presentation/bloc/activities_cubit.dart';
import '../../features/activities/presentation/widgets/activities_register_view.dart';
import '../../features/events/presentation/bloc/event_register_cubit.dart';
import '../../features/events/presentation/widgets/events_register_view.dart';
import '../../features/tasks/presentation/bloc/create_task_cubit.dart';
import '../../features/tasks/presentation/widgets/create_task_form.dart';
import '../../shared/shared.dart';
import '../di/service_locator.dart';

/// Hoja del FAB central: registra los tres tipos (Tarea/Actividad/Evento)
/// en <=2 toques. Compone tres features, por eso vive en core/navigation.
Future<void> showRegisterSheet(BuildContext context, {int initialTab = 1}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RegisterSheet(initialTab: initialTab),
  );
}

class _RegisterSheet extends StatefulWidget {
  const _RegisterSheet({required this.initialTab});

  final int initialTab;

  @override
  State<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<_RegisterSheet> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Gaps.vMd,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Registrar', style: AppTextStyles.headline),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Gaps.vMd,
                AppSegmentedButton(
                  expanded: true,
                  segments: const ['Tarea', 'Actividad', 'Evento'],
                  selectedIndex: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                Gaps.vLg,
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: switch (_tab) {
                      0 => BlocProvider(
                          create: (_) => sl<CreateTaskCubit>(),
                          child: CreateTaskForm(onCreated: () => Navigator.of(context).pop()),
                        ),
                      1 => BlocProvider(
                          create: (_) => sl<ActivitiesCubit>(),
                          child: const ActivitiesRegisterView(),
                        ),
                      _ => BlocProvider(
                          create: (_) => sl<EventRegisterCubit>(),
                          child: EventsRegisterView(
                              onSubmitted: () => Navigator.of(context).pop()),
                        ),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
