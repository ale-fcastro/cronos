import 'package:flutter/material.dart';
import '../../domain/entities/metrics_entities.dart';

const _accent = Color(0xFF9DB1F5);
const _success = Color(0xFF7EC9A2);
const _warning = Color(0xFFDDB168);
const _danger = Color(0xFFE0837A);
const _neutral = Color(0xFF3A3D45);
const _surfaceContainer = Color(0xFF24262B);

class MetricsMockDatasource {
  Future<MetricsSnapshot> fetchSnapshot() async {
    return const MetricsSnapshot(
      kpis: [
        KpiPoint(label: 'Cumplimiento', value: '81%', deltaLabel: '4', deltaImproving: true),
        KpiPoint(label: 'Eficiencia', value: '84%', deltaLabel: '2', deltaImproving: true),
        KpiPoint(label: 'Puntualidad', value: '72%', deltaLabel: '3', deltaImproving: false),
        KpiPoint(label: 'Precisión estim.', value: '±18%', deltaLabel: ' mejor', deltaImproving: true),
        KpiPoint(
            label: 'Tiempo perdido',
            value: '6h 12m',
            valueColor: _danger,
            deltaLabel: '48m',
            deltaImproving: true),
        KpiPoint(
            label: 'Fuera de horario',
            value: '3h 40m',
            valueColor: _warning,
            deltaLabel: '1h 05m',
            deltaImproving: false),
      ],
      totalTrackedLabel: '112h registradas',
      distribution: [
        WeightedSegment(fraction: 0.34, color: _accent, label: 'Trabajo 34%'),
        WeightedSegment(fraction: 0.29, color: _neutral, label: 'Sueño 29%'),
        WeightedSegment(fraction: 0.12, color: _success, label: 'Estudio 12%'),
        WeightedSegment(fraction: 0.09, color: _warning, label: 'Ocio 9%'),
        WeightedSegment(fraction: 0.16, color: _surfaceContainer, label: 'Otros 16%'),
      ],
      scoreEvolution: [0.38, 0.46, 0.41, 0.55, 0.50, 0.63, 0.59, 0.72],
      scoreEvolutionCurrentLabel: 'esta semana · 76',
    );
  }

  Future<TaskStatistics> fetchTaskStatistics() async {
    return const TaskStatistics(
      kpis: [
        KpiPoint(label: 'Duración promedio', value: '1h 24m'),
        KpiPoint(label: 'Desviación est/real', value: '+18%', valueColor: _warning),
        KpiPoint(label: 'Completadas', value: '24', valueColor: _success, deltaLabel: '3', deltaImproving: true),
        KpiPoint(label: 'Atrasadas', value: '5', valueColor: _danger, deltaLabel: '2', deltaImproving: false),
      ],
      deviationByProject: [
        ProjectDeviation(project: 'Tesis', label: '+32%', fraction: 0.82, color: _danger),
        ProjectDeviation(project: 'API Clientes', label: '+14%', fraction: 0.46, color: _warning),
        ProjectDeviation(project: 'Personal', label: '−6%', fraction: 0.18, color: _success),
      ],
      insight: 'Las tareas de Tesis duran un tercio más de lo estimado. '
          'Sugerencia: multiplica su estimación ×1.3.',
      closingPace: [0.52, 0.64, 0.58, 0.78],
      closingPaceCurrentLabel: '24 esta semana',
    );
  }

  Future<PhoneUsageStats> fetchPhoneUsage() async {
    return const PhoneUsageStats(
      kpis: [
        KpiPoint(label: 'Pantalla', value: '4h 32m'),
        KpiPoint(label: 'Desbloqueos', value: '126', valueColor: _warning),
        KpiPoint(label: 'Productivo', value: '68%', valueColor: _success),
      ],
      distribution: [
        WeightedSegment(fraction: 0.68, color: _success, label: 'Productiva 3h 05m'),
        WeightedSegment(fraction: 0.17, color: _neutral, label: 'Neutra 47m'),
        WeightedSegment(fraction: 0.15, color: _danger, label: 'No prod. 40m'),
      ],
      apps: [
        AppUsageRow(name: 'VS Code', subtitle: 'Trabajo · productiva', duration: '3h 00m', dotColor: _success),
        AppUsageRow(
            name: 'Duolingo',
            subtitle: 'Aprendizaje · objetivo 30m cumplido a las 9:40',
            duration: '2h 03m',
            dotColor: _success,
            subtitleColor: _success),
        AppUsageRow(
            name: 'YouTube',
            subtitle: 'Variable · clasificar sesión ›',
            duration: '1h 10m',
            dotColor: _warning,
            subtitleColor: _warning),
        AppUsageRow(
            name: 'Instagram',
            subtitle: 'Ocio · no productiva',
            duration: '54m',
            dotColor: _danger,
            durationColor: _danger),
        AppUsageRow(
            name: 'WhatsApp',
            subtitle: 'Comunicación · neutra · 87 aperturas',
            duration: '47m',
            dotColor: _neutral),
      ],
      insight: 'Planificaste estudiar 19:00–21:00, pero entre 19:30 y 20:10 usaste Instagram.',
    );
  }

  Future<EventsStatistics> fetchEventsStatistics() async {
    return const EventsStatistics(
      kpis: [
        KpiPoint(label: 'Tiempo', value: '8h 12m', valueColor: _danger),
        KpiPoint(label: 'Eventos', value: '23'),
        KpiPoint(label: 'Promedio', value: '21m'),
      ],
      originByPlace: [
        OriginRow(place: 'Trabajo', duration: '4h 00m', fraction: 0.49),
        OriginRow(place: 'Casa', duration: '2h 00m', fraction: 0.24),
        OriginRow(place: 'Transporte', duration: '1h 00m', fraction: 0.12),
        OriginRow(place: 'Otros', duration: '1h 12m', fraction: 0.15),
      ],
      recurrent: [
        RecurrentEvent(
            name: 'Reuniones improvisadas',
            subtitle: 'Interrupción · Trabajo',
            countLabel: '87 veces',
            avgLabel: 'prom 26m'),
        RecurrentEvent(
            name: 'Comprar comida',
            subtitle: 'Administrativo · 2.1 veces/sem',
            countLabel: '48 veces',
            avgLabel: 'prom 41m'),
        RecurrentEvent(
            name: 'Llamada con cliente',
            subtitle: 'Interrupción · Trabajo',
            countLabel: '18 veces',
            avgLabel: 'prom 17m'),
      ],
      insight: 'El 74% de tus sesiones largas de programación fueron '
          'interrumpidas por reuniones improvisadas.',
    );
  }
}
