import '../../domain/entities/habit.dart';
import '../../domain/repositories/habits_repository.dart';
import '../datasources/habits_local_datasource.dart';

class HabitsRepositoryImpl implements HabitsRepository {
  const HabitsRepositoryImpl(this._datasource);

  final HabitsLocalDatasource _datasource;

  @override
  Future<List<HabitWithStatus>> getHabits() => _datasource.fetchHabits();

  @override
  Future<void> createHabit(String title, {List<int>? targetWeekdays, String? areaId}) =>
      _datasource.createHabit(title, targetWeekdays: targetWeekdays, areaId: areaId);

  @override
  Future<void> archiveHabit(String id) => _datasource.archiveHabit(id);

  @override
  Future<void> toggleToday(String id) => _datasource.toggleToday(id);
}
