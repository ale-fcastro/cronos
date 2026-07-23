import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

/// Obtiene la foto del dia actual para la pantalla Hoy.
class GetTodaySummary {
  const GetTodaySummary(this._repository);

  final DashboardRepository _repository;

  Future<DashboardSummary> call() => _repository.getTodaySummary();
}
