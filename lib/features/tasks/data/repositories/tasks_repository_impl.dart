import '../../domain/entities/new_task_input.dart';
import '../../domain/entities/task_detail.dart';
import '../../domain/entities/task_summary.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../datasources/tasks_local_datasource.dart';

class TasksRepositoryImpl implements TasksRepository {
  const TasksRepositoryImpl(this._datasource);

  final TasksLocalDatasource _datasource;

  @override
  Future<List<TaskSummary>> getTasks({required String scope}) =>
      _datasource.fetchTasks(scope: scope);

  @override
  Future<TaskDetail> getTaskDetail(String id) => _datasource.fetchDetail(id);

  @override
  Future<void> startTimer(String id) => _datasource.startTimer(id);

  @override
  Future<void> pauseTimer(String id) => _datasource.pauseTimer(id);

  @override
  Future<void> completeTask(String id) => _datasource.completeTask(id);

  @override
  Future<void> createTask(NewTaskInput input) => _datasource.createTask(input);
}
