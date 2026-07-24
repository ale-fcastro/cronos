import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/models/event_category.dart';
import '../../../../core/navigation/profile_avatar.dart';
import '../../../../shared/shared.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';

/// Pantalla "Hoy": responde como va el dia en 3 segundos.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.avatarKey});

  /// Para el tour guiado del primer arranque (ver core/navigation).
  final GlobalKey? avatarKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoaded) {
          return const LoadingView();
        }
        final s = state.summary;
        return ListView(
          padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 96),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Headline('Hoy'),
                    const SizedBox(height: 2),
                    Subtitle(s.dateLabel),
                  ],
                ),
                avatarKey == null
                    ? const ProfileAvatar()
                    : Showcase(
                        key: avatarKey!,
                        title: 'Tu perfil',
                        description:
                            'Acá configurás huella, notificaciones, horarios y más.',
                        targetShapeBorder: const CircleBorder(),
                        child: const ProfileAvatar(),
                      ),
              ],
            ),
            Gaps.vLg,
            _ScoreCard(summary: s),
            Gaps.vMd,
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 2.6,
              children: [
                StatisticCard(label: 'Eficiencia', value: '${s.efficiencyPct}%'),
                StatisticCard(
                  label: 'Cumplimiento',
                  value: '${s.tasksDone}',
                  note: '/${s.tasksTotal}',
                ),
                StatisticCard(label: 'Trabajadas', value: s.workedLabel),
                StatisticCard(
                  label: 'Sueño',
                  value: s.sleepLabel,
                  valueColor: s.sleepBelowTarget ? AppColors.warning : null,
                  note: s.sleepDeltaLabel,
                ),
              ],
            ),
            Gaps.vMd,
            if (s.currentTask != null) _CurrentTaskCard(task: s.currentTask!),
            if (s.nextTask != null) ...[
              Gaps.vMd,
              _NextTaskRow(task: s.nextTask!),
            ],
            Gaps.vMd,
            SummaryCard(
              title: 'Score semanal',
              trailing: AppText.mono('media 74'),
              child: SizedBox(
                height: 56,
                child: MiniBarChart(
                  values: [for (final p in s.weeklyScores) p.value],
                  labels: [for (final p in s.weeklyScores) p.label],
                  highlightIndex: s.weeklyScores.indexWhere((p) => p.isToday),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircularScore(score: summary.score),
          Gaps.hLg,
          Expanded(
            child: Column(
              children: [
                _metricRow('Productivo', summary.productiveLabel, AppColors.success),
                Gaps.vSm,
                _metricRow('Perdido', summary.lostLabel, AppColors.danger),
                Gaps.vSm,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppText.secondary('vs ayer'),
                    TrendIndicator(
                      text: summary.vsYesterdayLabel,
                      improving: summary.vsYesterdayImproving,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.secondary(label),
        MetricLabel(value, color: color),
      ],
    );
  }
}

class _CurrentTaskCard extends StatelessWidget {
  const _CurrentTaskCard({required this.task});

  final CurrentTaskInfo task;

  @override
  Widget build(BuildContext context) {
    return HighlightSurface(
      child: Row(
        children: [
          const _PulseDot(),
          Gaps.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                AppCaption(task.subtitle),
              ],
            ),
          ),
          Gaps.hMd,
          MetricLabel(task.elapsedLabel, color: AppColors.accent, size: 16),
          Gaps.hMd,
          AppIconButton(
            icon: Icons.pause_rounded,
            onPressed: () async {
              final cubit = context.read<DashboardCubit>();
              if (task.kind != CurrentTrackKind.task && !task.isSleep) {
                cubit.pauseCurrent(task);
                return;
              }
              final reason = await PauseReasonDialog.show(
                context,
                reasons: task.kind == CurrentTrackKind.task
                    ? eventCategories
                    : sleepInterruptionReasons,
              );
              if (reason == null) return;
              cubit.pauseCurrent(task, reason: reason);
            },
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
    );
  }
}

class _NextTaskRow extends StatelessWidget {
  const _NextTaskRow({required this.task});

  final NextTaskInfo task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Text('SIGUIENTE',
              style: AppTextStyles.overline.copyWith(letterSpacing: 0.5)),
          Gaps.hSm,
          AppText.mono(task.time),
          Gaps.hSm,
          Text(task.title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
          Gaps.hXs,
          AppCaption('· ${task.project}'),
        ],
      ),
    );
  }
}
