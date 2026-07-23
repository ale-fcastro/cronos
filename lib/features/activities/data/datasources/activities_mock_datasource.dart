import 'package:flutter/material.dart';
import '../../domain/entities/activity_type.dart';

class ActivitiesMockDatasource {
  RunningActivity? _running = const RunningActivity(name: 'Descanso', elapsedLabel: '00:04:12');

  final List<ActivityType> _activities = const [
    ActivityType(id: 'dormir', name: 'Dormir', color: Color(0xFF3A3D45), lastUsedLabel: 'últ. 6h 51m'),
    ActivityType(id: 'comer', name: 'Comer', color: Color(0xFFDDB168), lastUsedLabel: 'últ. 58m'),
    ActivityType(
        id: 'ejercicio', name: 'Ejercicio', color: Color(0xFF7EC9A2), lastUsedLabel: 'últ. 45m · lun'),
    ActivityType(id: 'descanso', name: 'Descanso', color: Color(0xFF9DB1F5), lastUsedLabel: '3 hoy · 32m'),
    ActivityType(
        id: 'redes',
        name: 'Redes sociales',
        color: Color(0xFFE0837A),
        lastUsedLabel: '54m hoy',
        lastUsedWarn: true),
    ActivityType(id: 'videojuegos', name: 'Videojuegos', color: Color(0xFFE0837A), lastUsedLabel: 'últ. 1h 10m'),
    ActivityType(id: 'transporte', name: 'Transporte', color: Color(0xFF6A6F79), lastUsedLabel: 'últ. 50m'),
  ];

  final List<ActivityLogEntry> _log = const [
    ActivityLogEntry(time: '13:00', name: 'Comida', durationLabel: '58m'),
    ActivityLogEntry(time: '11:35', name: 'Redes sociales', durationLabel: '22m', warn: true),
    ActivityLogEntry(time: '08:10', name: 'Transporte', durationLabel: '50m'),
  ];

  Future<List<ActivityType>> fetchFrequent() async => List.of(_activities);

  Future<List<ActivityLogEntry>> fetchTodayLog() async => List.of(_log);

  Future<RunningActivity?> fetchRunning() async => _running;

  Future<void> start(String activityId) async {
    final activity = _activities.firstWhere((a) => a.id == activityId);
    _running = RunningActivity(name: activity.name, elapsedLabel: '00:00:00');
  }

  Future<void> stop() async {
    _running = null;
  }
}
