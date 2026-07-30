import '../entities/habit.dart';
import '../repositories/habits_repository.dart';

class GetHabits {
  const GetHabits(this._repository);
  final HabitsRepository _repository;
  Future<List<HabitWithStatus>> call() => _repository.getHabits();
}

class CreateHabit {
  const CreateHabit(this._repository);
  final HabitsRepository _repository;
  Future<void> call(String title, {List<int>? targetWeekdays, String? areaId}) =>
      _repository.createHabit(title, targetWeekdays: targetWeekdays, areaId: areaId);
}

class ArchiveHabit {
  const ArchiveHabit(this._repository);
  final HabitsRepository _repository;
  Future<void> call(String id) => _repository.archiveHabit(id);
}

class ToggleHabitToday {
  const ToggleHabitToday(this._repository);
  final HabitsRepository _repository;
  Future<void> call(String id) => _repository.toggleToday(id);
}
