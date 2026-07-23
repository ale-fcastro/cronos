import 'package:equatable/equatable.dart';
import '../../domain/entities/task_detail.dart';

class TaskDetailState extends Equatable {
  const TaskDetailState({this.detail});

  final TaskDetail? detail;

  bool get isLoading => detail == null;

  @override
  List<Object?> get props => [detail];
}
