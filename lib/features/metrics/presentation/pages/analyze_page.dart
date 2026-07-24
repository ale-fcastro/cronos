import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/profile_avatar.dart';
import '../../../../shared/shared.dart';
import '../../domain/entities/metrics_entities.dart';
import '../bloc/analyze_cubit.dart';
import '../bloc/analyze_state.dart';

const _tabLabels = ['Métricas', 'Tareas', 'Teléfono', 'Eventos'];
const _periodOptions = [
  ['Semana', 'Mes'],
  ['Semana', 'Mes'],
  ['Hoy', 'Semana'],
  ['Semana', 'Mes'],
];

/// Hub "Analizar": Métricas, Tareas, Teléfono y Eventos en un mismo lugar.
class AnalyzePage extends StatelessWidget {
  const AnalyzePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyzeCubit, AnalyzeState>(
      builder: (context, state) {
        if (state.isLoading) return const LoadingView();
        final cubit = context.read<AnalyzeCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Headline('Analizar'),
                Row(
                  children: [
                    AppSegmentedButton(
                      segments: _periodOptions[state.tabIndex],
                      selectedIndex: state.periodIndex,
                      onChanged: cubit.setPeriod,
                    ),
                    Gaps.hSm,
                    const ProfileAvatar(),
                  ],
                ),
              ],
            ),
            Gaps.vSm,
            Row(
              children: [
                for (var i = 0; i < _tabLabels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: GestureDetector(
                      onTap: () => cubit.setTab(i),
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: i == state.tabIndex
                                  ? AppColors.accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          _tabLabels[i],
                          style: TextStyle(
                            fontFamily: AppTextStyles.sans,
                            fontSize: 13,
                            fontWeight: i == state.tabIndex ? FontWeight.w600 : FontWeight.w400,
                            color: i == state.tabIndex
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 1),
            Gaps.vMd,
            Expanded(
              child: switch (state.tabIndex) {
                0 => _MetricsTab(snapshot: state.snapshot!),
                1 => _TasksStatsTab(stats: state.taskStats!),
                2 => _PhoneTab(usage: state.phoneUsage!),
                _ => _EventsTab(stats: state.eventsStats!),
              },
            ),
          ],
        );
      },
    );
  }
}

Widget _kpiGrid(List<KpiPoint> kpis, int columns) {
  return GridView.count(
    crossAxisCount: columns,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: AppSpacing.sm,
    crossAxisSpacing: AppSpacing.sm,
    childAspectRatio: columns == 3 ? 1.5 : 2.4,
    children: [
      for (final k in kpis)
        KpiTile(
          label: k.label,
          value: k.value,
          valueColor: k.valueColor,
          trend: k.deltaLabel == null
              ? null
              : TrendIndicator(text: k.deltaLabel!, improving: k.deltaImproving ?? true),
        ),
    ],
  );
}

class _MetricsTab extends StatelessWidget {
  const _MetricsTab({required this.snapshot});

  final MetricsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _kpiGrid(snapshot.kpis, 2),
        Gaps.vMd,
        SummaryCard(
          title: 'Distribución del tiempo',
          trailing: AppText.mono(snapshot.totalTrackedLabel),
          child: DistributionBar(
            segments: [
              for (final s in snapshot.distribution)
                DistributionSegment(value: s.fraction, color: s.color, label: s.label),
            ],
          ),
        ),
        Gaps.vMd,
        SummaryCard(
          title: 'Evolución del score · 8 días',
          trailing: Text('tendencia ▲',
              style: AppTextStyles.metricCaption.copyWith(color: AppColors.success)),
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: MiniBarChart(
                  values: snapshot.scoreEvolution,
                  highlightIndex: snapshot.scoreEvolution.length - 1,
                ),
              ),
              Gaps.vSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppCaption('d−7'),
                  Text(snapshot.scoreEvolutionCurrentLabel,
                      style: AppTextStyles.caption.copyWith(color: AppColors.accent)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TasksStatsTab extends StatelessWidget {
  const _TasksStatsTab({required this.stats});

  final TaskStatistics stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _kpiGrid(stats.kpis, 2),
        Gaps.vMd,
        SummaryCard(
          title: 'Desviación por proyecto',
          child: Column(
            children: [
              for (final p in stats.deviationByProject) ...[
                DeviationBar(
                  label: p.project,
                  valueLabel: p.label,
                  fraction: p.fraction,
                  color: p.color,
                ),
                if (p != stats.deviationByProject.last) Gaps.vMd,
              ],
              Gaps.vMd,
              Text(stats.insight, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.5)),
            ],
          ),
        ),
        Gaps.vMd,
        SummaryCard(
          title: 'Ritmo de cierre · 4 semanas',
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: MiniBarChart(
                  values: stats.closingPace,
                  highlightIndex: stats.closingPace.length - 1,
                  highlightColor: AppColors.success,
                ),
              ),
              Gaps.vSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppCaption('prom. ${stats.closingPaceAverageLabel}'),
                  Text(stats.closingPaceCurrentLabel,
                      style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhoneTab extends StatelessWidget {
  const _PhoneTab({required this.usage});

  final PhoneUsageStats usage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _kpiGrid(usage.kpis, 3),
        Gaps.vMd,
        SummaryCard(
          title: 'Tiempo en pantalla por tipo',
          child: DistributionBar(
            segments: [
              for (final s in usage.distribution)
                DistributionSegment(value: s.fraction, color: s.color, label: s.label),
            ],
          ),
        ),
        Gaps.vMd,
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final app in usage.apps)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: app == usage.apps.last
                        ? null
                        : const Border(bottom: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      AppIconAvatar(name: app.name, icon: app.icon, color: app.dotColor),
                      Gaps.hMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(app.name, style: AppTextStyles.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w500)),
                            Text(app.subtitle,
                                style: AppTextStyles.caption
                                    .copyWith(color: app.subtitleColor ?? AppColors.textTertiary)),
                          ],
                        ),
                      ),
                      Text(app.duration,
                          style: AppTextStyles.body.copyWith(
                              fontFamily: AppTextStyles.mono,
                              fontSize: 13,
                              color: app.durationColor)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Gaps.vMd,
        InsightCard(text: usage.insight),
      ],
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({required this.stats});

  final EventsStatistics stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _kpiGrid(stats.kpis, 3),
        Gaps.vMd,
        SummaryCard(
          title: 'Origen del tiempo perdido',
          child: Column(
            children: [
              for (final o in stats.originByPlace) ...[
                LinearProgressCard(label: o.place, progress: o.fraction, valueLabel: o.duration),
                if (o != stats.originByPlace.last) Gaps.vMd,
              ],
            ],
          ),
        ),
        Gaps.vMd,
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Eventos recurrentes',
                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
              for (final r in stats.recurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    border: r == stats.recurrent.last
                        ? null
                        : const Border(bottom: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name,
                                style: AppTextStyles.body
                                    .copyWith(fontSize: 13.5, fontWeight: FontWeight.w500)),
                            AppCaption(r.subtitle),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppText.mono(r.countLabel),
                          AppCaption(r.avgLabel),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Gaps.vMd,
        InsightCard(text: stats.insight),
      ],
    );
  }
}
