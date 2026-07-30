import 'package:equatable/equatable.dart';
import '../../domain/entities/habit.dart';

class HabitsState extends Equatable {
  const HabitsState({this.habits = const [], this.loading = true});

  final List<HabitWithStatus> habits;
  final bool loading;

  HabitsState copyWith({List<HabitWithStatus>? habits, bool? loading}) {
    return HabitsState(
      habits: habits ?? this.habits,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [habits, loading];
}
