import '../entities/dashboard_summary.dart';

/// Contrato del dominio: como obtener la foto del dia actual.
abstract interface class DashboardRepository {
  Future<DashboardSummary> getTodaySummary();
}
