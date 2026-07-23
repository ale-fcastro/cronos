import '../entities/month_overview.dart';
import '../entities/timeline_entry.dart';

abstract interface class ScheduleRepository {
  Future<AgendaDay> getDayAgenda(DateTime date);
  Future<MonthOverview> getMonthOverview(DateTime month);
}
