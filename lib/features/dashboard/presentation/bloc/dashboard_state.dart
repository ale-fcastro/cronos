import 'package:equatable/equatable.dart';
import '../../../../core/models/life_area.dart';
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
  const DashboardLoaded(this.summary, {this.lifeAreas = const []});

  final DashboardSummary summary;
  final List<LifeArea> lifeAreas;

  @override
  List<Object?> get props => [summary, lifeAreas];
}
