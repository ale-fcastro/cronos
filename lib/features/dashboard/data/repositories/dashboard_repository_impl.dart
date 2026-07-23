import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_mock_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._datasource);

  final DashboardMockDatasource _datasource;

  @override
  Future<DashboardSummary> getTodaySummary() => _datasource.fetchTodaySummary();
}
