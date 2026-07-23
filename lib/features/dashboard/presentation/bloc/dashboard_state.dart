import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_summary.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.summary);

  final DashboardSummary summary;

  @override
  List<Object?> get props => [summary];
}
