import '../../domain/entities/month_overview.dart';
import '../../domain/entities/timeline_entry.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_local_datasource.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl(this._datasource);

  final ScheduleLocalDatasource _datasource;

  @override
  Future<AgendaDay> getDayAgenda(DateTime date) => _datasource.fetchDayAgenda(date);

  @override
  Future<MonthOverview> getMonthOverview(DateTime month) =>
      _datasource.fetchMonthOverview(month);
}
