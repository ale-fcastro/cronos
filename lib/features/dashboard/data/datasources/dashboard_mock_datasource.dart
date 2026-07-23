import '../../domain/entities/dashboard_summary.dart';

/// Datos de ejemplo del usuario (dev que trabaja y estudia) usados por el mockup.
class DashboardMockDatasource {
  Future<DashboardSummary> fetchTodaySummary() async {
    return const DashboardSummary(
      dateLabel: 'Miércoles, 23 de julio',
      score: 78,
      productiveLabel: '5h 42m',
      lostLabel: '1h 08m',
      vsYesterdayLabel: '5 pts',
      vsYesterdayImproving: true,
      efficiencyPct: 84,
      tasksDone: 6,
      tasksTotal: 8,
      workedLabel: '4h 10m',
      sleepLabel: '6h 51m',
      sleepDeltaLabel: '−1h 09m',
      sleepBelowTarget: true,
      currentTask: CurrentTaskInfo(
        title: 'Deep work — API Clientes',
        subtitle: 'En curso · est. 2h 30m',
        elapsedLabel: '00:42:13',
      ),
      nextTask: NextTaskInfo(
        time: '16:30',
        title: 'Revisión de PRs',
        project: 'API Clientes',
      ),
      weeklyScores: [
        DayScorePoint(label: 'J', value: 0.62),
        DayScorePoint(label: 'V', value: 0.74),
        DayScorePoint(label: 'S', value: 0.43),
        DayScorePoint(label: 'D', value: 0.52),
        DayScorePoint(label: 'L', value: 0.69),
        DayScorePoint(label: 'M', value: 0.79),
        DayScorePoint(label: 'X', value: 0.86, isToday: true),
      ],
    );
  }
}
