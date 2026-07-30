import '../entities/habit.dart';

abstract interface class HabitsRepository {
  Future<List<HabitWithStatus>> getHabits();
  Future<void> createHabit(String title, {List<int>? targetWeekdays, String? areaId});
  Future<void> archiveHabit(String id);
  Future<void> toggleToday(String id);
}
