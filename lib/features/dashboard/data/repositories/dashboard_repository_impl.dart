import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._datasource);

  final DashboardLocalDatasource _datasource;

  @override
  Future<DashboardSummary> getTodaySummary() => _datasource.fetchTodaySummary();
}
