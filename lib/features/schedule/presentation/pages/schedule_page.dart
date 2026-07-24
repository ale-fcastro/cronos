import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/models/event_category.dart';
import '../../../../shared/shared.dart';
import '../../domain/entities/month_overview.dart';
import '../../domain/entities/timeline_entry.dart';
import '../bloc/schedule_cubit.dart';
import '../bloc/schedule_state.dart';

/// Pantalla Agenda: linea de tiempo del dia o calendario del mes.
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        if (state.isLoading) return const LoadingView();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Headline('Agenda'),
                    const SizedBox(height: 2),
                    Subtitle(state.viewMode == ScheduleViewMode.day
                        ? state.day!.dateLabel
                        : 'Score medio del mes · ${state.month!.averageScore}'),
                  ],
                ),
                AppSegmentedButton(
                  segments: const ['Día', 'Mes'],
                  selectedIndex: state.viewMode == ScheduleViewMode.day ? 0 : 1,
                  onChanged: (i) => context.read<ScheduleCubit>().setViewMode(
                      i == 0 ? ScheduleViewMode.day : ScheduleViewMode.month),
                ),
              ],
            ),
            Gaps.vLg,
            Expanded(
              child: state.viewMode == ScheduleViewMode.day
                  ? _DayTimeline(entries: state.day!.entries)
                  : _MonthView(month: state.month!),
            ),
          ],
        );
      },
    );
  }
}

class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.entries});

  final List<TimelineEntry> entries;

  Future<void> _openTaskDetail(BuildContext context, String? taskId) async {
    if (taskId == null) return;
    await Navigator.of(context).pushNamed(AppRoutes.taskDetail, arguments: taskId);
    if (!context.mounted) return;
    context.read<ScheduleCubit>().reload();
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.subject_rounded,
        title: 'Sin plan para hoy',
        message: 'Creá una tarea o registrá una actividad desde el botón + '
            'y aparecerán acá en su línea de tiempo.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: entries.length,
      separatorBuilder: (_, __) => Gaps.vSm,
      itemBuilder: (context, i) => _entryRow(context, entries[i]),
    );
  }

  Widget _entryRow(BuildContext context, TimelineEntry e) {
    switch (e.kind) {
      case TimelineEntryKind.lateMarker:
        return InkWell(
          onTap: e.taskId == null ? null : () => _openTaskDetail(context, e.taskId),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Row(
              children: [
                const Expanded(child: Divider(color: AppColors.danger, height: 1)),
                const SizedBox(width: 8),
                Text(e.time,
                    style:
                        AppTextStyles.metricCaption.copyWith(color: AppColors.danger, fontSize: 10)),
              ],
            ),
          ),
        );
      case TimelineEntryKind.sessionMarker:
        return InkWell(
          onTap: e.taskId == null ? null : () => _openTaskDetail(context, e.taskId),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                      color: (e.accentColor ?? AppColors.textTertiary).withValues(alpha: 0.35),
                      height: 1),
                ),
                const SizedBox(width: 8),
                Text('${e.subtitle} · ${e.time}',
                    style: AppTextStyles.metricCaption
                        .copyWith(color: e.accentColor ?? AppColors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        );
      case TimelineEntryKind.gap:
        return TimelineRow(
          time: e.time,
          child: DashedSurface(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hueco libre', style: AppTextStyles.caption),
                if (e.trailingLabel != null) AppText.mono(e.trailingLabel!),
              ],
            ),
          ),
        );
      case TimelineEntryKind.runningBlock:
        return TimelineRow(
          time: e.time,
          timeColor: AppColors.accent,
          emphasized: true,
          child: HighlightSurface(
            onTap: e.taskId == null ? null : () => _openTaskDetail(context, e.taskId),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration:
                          const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    ),
                    Gaps.hSm,
                    Expanded(
                      child: Text(e.title ?? '',
                          style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (e.subtitle != null) ...[
                  const SizedBox(height: 3),
                  AppCaption(e.subtitle!),
                ],
                Gaps.vSm,
                Row(
                  children: [
                    if (e.elapsedLabel != null)
                      MetricLabel(e.elapsedLabel!, color: AppColors.accent, size: 17),
                    Gaps.hMd,
                    if (e.progress != null)
                      Expanded(child: LinearProgressCard(label: '', progress: e.progress!)),
                    Gaps.hMd,
                    SecondaryButton(
                      label: 'Pausar',
                      onPressed: e.taskId == null
                          ? null
                          : () async {
                              final cubit = context.read<ScheduleCubit>();
                              final reason = await PauseReasonDialog.show(
                                context,
                                reasons: eventCategories,
                              );
                              if (reason == null) return;
                              cubit.pauseTask(e.taskId!, reason: reason);
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case TimelineEntryKind.block:
        return TimelineRow(
          time: e.time,
          timeColor: e.late ? AppColors.danger : null,
          child: AppCard(
            padding: AppSpacing.cardDense,
            borderColor: e.late ? AppColors.danger.withValues(alpha: 0.35) : null,
            onTap: e.taskId == null ? null : () => _openTaskDetail(context, e.taskId),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 22,
                  decoration: BoxDecoration(
                    color: e.accentColor ?? AppColors.neutralBar,
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                  ),
                ),
                Gaps.hSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title ?? '', style: AppTextStyles.title.copyWith(fontSize: 13)),
                      if (e.subtitle != null)
                        Text(e.subtitle!,
                            style: AppTextStyles.caption
                                .copyWith(color: e.late ? AppColors.danger : null)),
                    ],
                  ),
                ),
                if (e.trailingLabel != null) AppText.mono(e.trailingLabel!),
                if (e.showPlay) ...[
                  Gaps.hSm,
                  _PlayCircle(
                    onTap: e.taskId == null
                        ? null
                        : () => context.read<ScheduleCubit>().startTask(e.taskId!),
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }
}

class _PlayCircle extends StatelessWidget {
  const _PlayCircle({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          border: Border.fromBorderSide(BorderSide(color: AppColors.borderStrong, width: 1.5)),
        ),
        child: const Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({required this.month});

  final MonthOverview month;

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  for (final l in weekdayLabels)
                    Expanded(
                      child: Center(
                        child: Text(l, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                      ),
                    ),
                ],
              ),
              Gaps.vSm,
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (var i = 0; i < month.leadingBlankCells; i++) const SizedBox.shrink(),
                  for (final d in month.days)
                    HeatmapCell(
                      label: '${d.day}',
                      intensity: d.intensity,
                      selected: d.selected,
                    ),
                ],
              ),
              Gaps.vMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const AppCaption('score bajo'),
                  Gaps.hSm,
                  _legendSwatch(0.10),
                  const SizedBox(width: 4),
                  _legendSwatch(0.30),
                  const SizedBox(width: 4),
                  _legendSwatch(0.60),
                  Gaps.hSm,
                  const AppCaption('alto'),
                ],
              ),
            ],
          ),
        ),
        Gaps.vMd,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(month.selectedDayLabel, style: AppTextStyles.title),
                  AppText.mono('score ${month.selectedDayScore}',
                      style: const TextStyle(color: AppColors.accent)),
                ],
              ),
              Gaps.vMd,
              DistributionBar(
                segments: [
                  for (final s in month.selectedDaySegments)
                    DistributionSegment(value: s.fraction, color: s.color, label: s.label),
                ],
              ),
              Gaps.vMd,
              const Divider(),
              Gaps.vSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText.secondary('Tareas cumplidas'),
                  AppText.mono('${month.tasksDone}/${month.tasksTotal}'),
                ],
              ),
              Gaps.vSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText.secondary('Bloques planificados vs vividos'),
                  AppText.mono('${month.plannedVsLivedPct}%'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendSwatch(double alpha) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: alpha),
        borderRadius: const BorderRadius.all(Radius.circular(3)),
      ),
    );
  }
}
