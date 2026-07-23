import '../entities/month_overview.dart';
import '../repositories/schedule_repository.dart';

class GetMonthOverview {
  const GetMonthOverview(this._repository);

  final ScheduleRepository _repository;

  Future<MonthOverview> call(DateTime month) => _repository.getMonthOverview(month);
}
