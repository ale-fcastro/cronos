import 'package:equatable/equatable.dart';

/// Hábito con seguimiento diario (check + racha). A diferencia de una tarea
/// recurrente, no tiene cronómetro ni horario: es un simple hecho/no hecho
/// por día.
class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.title,
    this.targetWeekdays,
    this.areaId,
  });

  final String id;
  final String title;

  /// Días de la semana en los que cuenta (1 = lunes .. 7 = domingo).
  /// `null` significa todos los días.
  final List<int>? targetWeekdays;
  final String? areaId;

  @override
  List<Object?> get props => [id, title, targetWeekdays, areaId];
}

/// Un hábito junto con su estado de hoy y su racha actual, listo para mostrar.
class HabitWithStatus extends Equatable {
  const HabitWithStatus({
    required this.habit,
    required this.doneToday,
    required this.streak,
  });

  final Habit habit;
  final bool doneToday;
  final int streak;

  @override
  List<Object?> get props => [habit, doneToday, streak];
}
