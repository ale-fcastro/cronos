import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/event_category.dart';
import '../../../../shared/shared.dart';
import '../bloc/activities_cubit.dart';
import '../bloc/activities_state.dart';
import 'create_activity_type_dialog.dart';

/// Contenido de la pestaña "Actividad" de la hoja de registro del FAB.
class ActivitiesRegisterView extends StatelessWidget {
  const ActivitiesRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivitiesCubit, ActivitiesState>(
      builder: (context, state) {
        if (state.isLoading) return const LoadingView();
        final cubit = context.read<ActivitiesCubit>();
        return ListView(
          shrinkWrap: true,
          children: [
            if (state.running != null) ...[
              HighlightSurface(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    ),
                    Gaps.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.running!.name, style: AppTextStyles.title),
                          const AppCaption('en curso'),
                        ],
                      ),
                    ),
                    MetricLabel(state.running!.elapsedLabel, color: AppColors.accent, size: 16),
                    Gaps.hMd,
                    AppIconButton(
                      icon: Icons.stop_rounded,
                      onPressed: () async {
                        if (!state.running!.isSleep) {
                          cubit.stop();
                          return;
                        }
                        final reason = await PauseReasonDialog.show(
                          context,
                          reasons: sleepInterruptionReasons,
                        );
                        if (reason == null) return;
                        cubit.stop(reason: reason);
                      },
                    ),
                  ],
                ),
              ),
              Gaps.vMd,
            ],
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.7,
              children: [
                for (final a in state.activities!)
                  ActivityCard(
                    name: a.name,
                    color: a.color,
                    lastUsed: a.lastUsedLabel,
                    lastUsedColor: a.lastUsedWarn ? AppColors.danger : null,
                    onTap: () => cubit.start(a.id),
                  ),
                DashedSurface(
                  onTap: () async {
                    final input = await showCreateActivityTypeDialog(
                      context,
                      lifeAreas: state.lifeAreas,
                    );
                    if (input != null) cubit.createActivityType(input);
                  },
                  child: SizedBox(
                    height: 62,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_rounded, size: 16, color: AppColors.textTertiary),
                        SizedBox(width: 8),
                        Text('Nueva actividad', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Gaps.vMd,
            SectionHeader(title: 'Hoy'),
            for (final entry in state.log!)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                        width: 36,
                        child: AppText.mono(entry.time,
                            style: const TextStyle(color: AppColors.textTertiary))),
                    Gaps.hMd,
                    Expanded(child: Text(entry.name, style: AppTextStyles.body)),
                    AppText.mono(entry.durationLabel,
                        style: TextStyle(color: entry.warn ? AppColors.danger : null)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
