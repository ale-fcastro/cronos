import '../entities/timeline_entry.dart';
import '../repositories/schedule_repository.dart';

class GetDayAgenda {
  const GetDayAgenda(this._repository);

  final ScheduleRepository _repository;

  Future<AgendaDay> call(DateTime date) => _repository.getDayAgenda(date);
}
