import 'package:equatable/equatable.dart';
import '../../../../core/models/life_area.dart';
import '../../domain/entities/task_detail.dart';

class TaskDetailState extends Equatable {
  const TaskDetailState({this.detail, this.deleted = false, this.lifeAreas = const []});

  final TaskDetail? detail;
  final bool deleted;
  final List<LifeArea> lifeAreas;

  bool get isLoading => detail == null;

  @override
  List<Object?> get props => [detail, deleted, lifeAreas];
}
