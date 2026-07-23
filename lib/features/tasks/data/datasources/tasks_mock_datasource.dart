import '../../domain/entities/new_task_input.dart';
import '../../domain/entities/task_detail.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_summary.dart';

/// Almacen en memoria con los datos de ejemplo del mockup. Mutable para que
/// las acciones de la UI (iniciar/pausar/completar/crear) tengan efecto real.
class TasksMockDatasource {
  final List<TaskSummary> _tasks = [
    const TaskSummary(
      id: 't1',
      title: 'Deep work — API Clientes',
      priority: TaskPriority.p1,
      status: TaskStatus.running,
      project: 'API Clientes',
      plannedTime: '09:00',
      timeInfo: 'est 2h30 · real 0h42',
    ),
    const TaskSummary(
      id: 't2',
      title: 'Revisión de PRs',
      priority: TaskPriority.p2,
      status: TaskStatus.normal,
      project: 'API Clientes',
      plannedTime: '12:00',
      timeInfo: 'est 45m',
    ),
    const TaskSummary(
      id: 't3',
      title: 'Tesis — capítulo 3',
      priority: TaskPriority.p1,
      status: TaskStatus.normal,
      project: 'Tesis',
      plannedTime: '14:00',
      timeInfo: 'est 2h',
    ),
    const TaskSummary(
      id: 't4',
      title: 'Actualizar informe semanal',
      priority: TaskPriority.p2,
      status: TaskStatus.late,
      project: 'API Clientes',
      plannedTime: 'ayer 17:00',
      timeInfo: 'est 30m',
    ),
    const TaskSummary(
      id: 't5',
      title: 'Pagar matrícula',
      priority: TaskPriority.p3,
      status: TaskStatus.done,
      project: 'Personal',
      timeInfo: 'est 10m · real 8m',
    ),
    const TaskSummary(
      id: 't6',
      title: 'Responder correos',
      priority: TaskPriority.p2,
      status: TaskStatus.done,
      project: 'API Clientes',
      timeInfo: 'est 20m · real 34m +70%',
    ),
  ];

  final Map<String, TaskDetail> _details = {
    't1': const TaskDetail(
      id: 't1',
      title: 'Deep work — API Clientes',
      priority: TaskPriority.p1,
      status: TaskStatus.running,
      project: 'API Clientes',
      elapsedLabel: '01:47:22',
      estimateLabel: '2h 30m',
      progress: 0.71,
      plannedTime: '09:00',
      startedTime: '09:00',
      sessionsCount: 3,
      notes: 'Terminar endpoint de facturación. Revisar validación de fechas '
          'antes de abrir el PR. Ayer quedó pendiente el caso de zona horaria.',
      history: [
        TaskSession(rangeLabel: 'Hoy · 10:24 — ahora', durationLabel: '35m', running: true),
        TaskSession(rangeLabel: 'Hoy · 09:00 — 10:12', durationLabel: '1h 12m'),
        TaskSession(rangeLabel: 'Ayer · 16:00 — 16:20', durationLabel: '20m'),
      ],
    ),
  };

  Future<List<TaskSummary>> fetchTasks({required String scope}) async => List.of(_tasks);

  Future<TaskDetail> fetchDetail(String id) async {
    return _details[id] ?? _details['t1']!;
  }

  Future<void> startTimer(String id) async {
    _replace(id, (t) => t.copyWith(status: TaskStatus.running));
  }

  Future<void> pauseTimer(String id) async {
    _replace(id, (t) => t.copyWith(status: TaskStatus.normal));
  }

  Future<void> completeTask(String id) async {
    _replace(id, (t) => t.copyWith(status: TaskStatus.done));
  }

  Future<void> createTask(NewTaskInput input) async {
    _tasks.add(TaskSummary(
      id: 't${_tasks.length + 1}',
      title: input.title,
      priority: input.priority,
      status: TaskStatus.normal,
      project: input.project,
      plannedTime: input.timeLabel,
      timeInfo: 'est ${input.estimateMinutes ~/ 60}h${input.estimateMinutes % 60}m',
    ));
  }

  void _replace(String id, TaskSummary Function(TaskSummary) update) {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i != -1) _tasks[i] = update(_tasks[i]);
  }
}
