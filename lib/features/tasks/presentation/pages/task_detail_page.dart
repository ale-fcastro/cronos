import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/models/event_category.dart';
import '../../../../core/models/life_area.dart';
import '../../../../core/services/linked_app_guard_service.dart';
import '../../../../shared/shared.dart';
import '../../../../shared/shared.dart' as ds show TaskPriority;
import '../../domain/entities/task_detail.dart';
import '../../domain/entities/task_priority.dart' as domain;
import '../../domain/entities/task_summary.dart';
import '../bloc/create_task_cubit.dart';
import '../bloc/task_detail_cubit.dart';
import '../bloc/task_detail_state.dart';
import '../widgets/complete_task_dialog.dart';
import '../widgets/create_task_form.dart';

/// Pantalla empujada con el detalle de una tarea: estimado vs real e historial.
class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TaskDetailCubit>(param1: taskId),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.page,
            child: BlocConsumer<TaskDetailCubit, TaskDetailState>(
              listener: (context, state) {
                if (state.deleted) Navigator.of(context).pop();
              },
              builder: (context, state) {
                if (state.isLoading) return const LoadingView();
                final d = state.detail!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Breadcrumb(
                          parentLabel: 'Tareas',
                          onBack: () => Navigator.of(context).pop(),
                        ),
                        Row(
                          children: [
                            AppIconButton(
                              icon: Icons.edit_outlined,
                              onPressed: () => _editTask(context, d),
                            ),
                            Gaps.hSm,
                            AppIconButton(
                              icon: Icons.delete_outline_rounded,
                              color: AppColors.danger,
                              onPressed: () async {
                                final confirmed = await DeleteDialog.show(
                                  context,
                                  title: 'Eliminar "${d.title}"',
                                  message: 'Se borra la tarea y su historial de sesiones.',
                                );
                                if (confirmed && context.mounted) {
                                  context.read<TaskDetailCubit>().delete();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    Gaps.vSm,
                    Text(d.title, style: AppTextStyles.headline),
                    Gaps.vSm,
                    Row(
                      children: [
                        PriorityBadge(priority: _mapPriority(d.priority)),
                        Gaps.hSm,
                        AppActionChip(label: d.project),
                        Gaps.hSm,
                        if (d.status == TaskStatus.running)
                          StatusBadge(label: 'En curso', color: AppColors.accent)
                        else if (d.status == TaskStatus.done)
                          StatusBadge(label: 'Hecha', color: AppColors.success)
                        else if (d.status == TaskStatus.notDone)
                          StatusBadge(label: 'No hecha', color: AppColors.danger),
                      ],
                    ),
                    if (d.notDoneReason != null) ...[
                      Gaps.vSm,
                      Text('No hecha: ${d.notDoneReason}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.danger)),
                    ],
                    if (d.linkedAppName != null) ...[
                      Gaps.vSm,
                      Row(
                        children: [
                          Icon(
                            d.appVerified == true
                                ? Icons.verified_rounded
                                : Icons.link_rounded,
                            size: 14,
                            color: d.appVerified == true
                                ? AppColors.success
                                : AppColors.textTertiary,
                          ),
                          Gaps.hXs,
                          Text(
                            d.appVerified == true
                                ? 'Verificado con ${d.linkedAppName}'
                                : 'Vinculada a ${d.linkedAppName}',
                            style: AppTextStyles.caption.copyWith(
                              color: d.appVerified == true
                                  ? AppColors.success
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    Gaps.vLg,
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 32),
                        children: [
                          _TimerCard(detail: d, lifeAreas: state.lifeAreas),
                          Gaps.vMd,
                          Row(
                            children: [
                              Expanded(
                                child: StatisticCard(label: 'Planificada', value: d.plannedTime),
                              ),
                              Gaps.hSm,
                              Expanded(
                                child: StatisticCard(
                                  label: 'Iniciada',
                                  value: d.startedTime,
                                  valueColor: AppColors.success,
                                ),
                              ),
                              Gaps.hSm,
                              Expanded(
                                child: StatisticCard(
                                    label: 'Sesiones', value: '${d.sessionsCount}'),
                              ),
                            ],
                          ),
                          Gaps.vMd,
                          _SubtasksCard(taskId: d.id, subtasks: d.subtasks),
                          Gaps.vMd,
                          SummaryCard(
                            title: 'Historial',
                            child: Column(
                              children: [
                                for (final h in d.history) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: h.running
                                                  ? AppColors.accent
                                                  : AppColors.neutralBar,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Gaps.hSm,
                                          Text(h.rangeLabel,
                                              style: AppTextStyles.body.copyWith(fontSize: 12.5)),
                                        ],
                                      ),
                                      AppText.mono(h.durationLabel,
                                          style: TextStyle(
                                              color: h.running
                                                  ? AppColors.accent
                                                  : AppColors.textSecondary)),
                                    ],
                                  ),
                                  if (h != d.history.last) Gaps.vSm,
                                ],
                              ],
                            ),
                          ),
                          if (d.notes != null) ...[
                            Gaps.vMd,
                            SummaryCard(
                              title: 'Notas',
                              child: Text(d.notes!,
                                  style: AppTextStyles.body.copyWith(
                                      fontSize: 13, color: AppColors.textPrimary, height: 1.55)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre "Editar tarea" en una hoja modal (mismo formulario que "Nueva
/// tarea", en modo edición) y refresca el detalle al cerrarla.
Future<void> _editTask(BuildContext context, TaskDetail d) async {
  final detailCubit = context.read<TaskDetailCubit>();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Gaps.vMd,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Editar tarea', style: AppTextStyles.headline),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                Gaps.vLg,
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: BlocProvider(
                      create: (_) => sl<CreateTaskCubit>(param1: d.id),
                      child: CreateTaskForm(
                        initialTitle: d.title,
                        onSubmitted: () => Navigator.of(sheetContext).pop(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  detailCubit.load();
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.detail, this.lifeAreas = const []});

  final TaskDetail detail;
  final List<LifeArea> lifeAreas;

  @override
  Widget build(BuildContext context) {
    final running = detail.status == TaskStatus.running;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          Column(
            children: [
              Text(detail.elapsedLabel, style: AppTextStyles.metricDisplay),
              const AppCaption('tiempo real acumulado'),
            ],
          ),
          if (detail.pauseReason != null) ...[
            Gaps.vMd,
            HighlightSurface(
              padding: AppSpacing.cardDense,
              child: Row(
                children: [
                  const Icon(Icons.pause_circle_outline_rounded,
                      size: 18, color: AppColors.accent),
                  Gaps.hSm,
                  Expanded(
                    child: Text('En pausa · ${detail.pauseReason}',
                        style: AppTextStyles.title.copyWith(color: AppColors.accent)),
                  ),
                  if (detail.pausedElapsedLabel != null)
                    MetricLabel(detail.pausedElapsedLabel!, color: AppColors.accent),
                ],
              ),
            ),
          ],
          Gaps.vMd,
          LinearProgressCard(
            label: 'Estimado ${detail.estimateLabel}',
            progress: detail.progress,
            valueLabel: '${(detail.progress * 100).round()}%',
          ),
          Gaps.vMd,
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: running ? 'Pausar' : 'Reanudar',
                  icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  onPressed: () async {
                    final cubit = context.read<TaskDetailCubit>();
                    if (!running) {
                      final linked = await sl<LinkedAppGuardService>().getLinkedApp(detail.id);
                      if (linked != null) {
                        if (!context.mounted) return;
                        final opened = await OpenLinkedAppDialog.show(
                          context,
                          packageName: linked.packageName,
                          appName: linked.appName,
                        );
                        if (!opened) return;
                      }
                      cubit.resume();
                      return;
                    }
                    final result = await PauseReasonDialog.show(
                      context,
                      reasons: eventCategories,
                      areas: lifeAreas,
                    );
                    if (result == null) return;
                    cubit.pause(reason: result.reason, areaId: result.areaId);
                  },
                ),
              ),
              Gaps.hSm,
              Expanded(
                child: PrimaryButton(
                  label: 'Finalizar',
                  onPressed: () => _finalize(context, detail),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

ds.TaskPriority _mapPriority(domain.TaskPriority p) => switch (p) {
      domain.TaskPriority.p1 => ds.TaskPriority.p1,
      domain.TaskPriority.p2 => ds.TaskPriority.p2,
      domain.TaskPriority.p3 => ds.TaskPriority.p3,
    };

/// No deja finalizar con subtareas pendientes; si no hay ninguna pendiente,
/// pregunta antes de completar (ver [showCompleteTaskDialog]) en vez de
/// cerrarla en un solo toque.
Future<void> _finalize(BuildContext context, TaskDetail detail) async {
  final pending = detail.subtasks.where((s) => !s.done).length;
  if (pending > 0) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pending == 1
          ? 'Todavía tenés 1 subtarea sin terminar.'
          : 'Todavía tenés $pending subtareas sin terminar.'),
    ));
    return;
  }
  final cubit = context.read<TaskDetailCubit>();
  final result = await showCompleteTaskDialog(
    context,
    title: detail.title,
    hasTrackedTime: detail.sessionsCount > 0,
  );
  switch (result) {
    case CompleteTaskDone(:final start, :final end):
      cubit.finish(manualStart: start, manualEnd: end);
    case CompleteTaskFailed(:final reason):
      cubit.markNotDone(reason);
    case null:
      break;
  }
}

class _SubtasksCard extends StatefulWidget {
  const _SubtasksCard({required this.taskId, required this.subtasks});

  final String taskId;
  final List<Subtask> subtasks;

  @override
  State<_SubtasksCard> createState() => _SubtasksCardState();
}

class _SubtasksCardState extends State<_SubtasksCard> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _add(TaskDetailCubit cubit) {
    if (_titleController.text.trim().isEmpty) return;
    cubit.addSubtask(_titleController.text, description: _descController.text);
    _titleController.clear();
    _descController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskDetailCubit>();
    final done = widget.subtasks.where((s) => s.done).length;
    return SummaryCard(
      title: 'Subtareas',
      trailing: widget.subtasks.isEmpty
          ? null
          : AppCaption('$done/${widget.subtasks.length}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in widget.subtasks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: s.done,
                      onChanged: (v) => cubit.toggleSubtask(s.id, v ?? false),
                      activeColor: AppColors.accent,
                    ),
                  ),
                  Gaps.hSm,
                  Expanded(
                    child: InkWell(
                      onTap: () => _editSubtask(context, cubit, s),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 13,
                                color: s.done ? AppColors.textTertiary : AppColors.textPrimary,
                                decoration: s.done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (s.description != null && s.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  s.description!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: s.done
                                        ? AppColors.textTertiary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    size: 26,
                    color: AppColors.textTertiary,
                    onPressed: () => cubit.deleteSubtask(s.id),
                  ),
                ],
              ),
            ),
          if (widget.subtasks.isNotEmpty) Gaps.vSm,
          AppTextField(
            hint: 'Título de la subtarea…',
            controller: _titleController,
            onChanged: (_) => setState(() {}),
          ),
          Gaps.vSm,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  hint: 'Descripción (opcional)',
                  controller: _descController,
                ),
              ),
              Gaps.hSm,
              AppIconButton(
                icon: Icons.add_rounded,
                onPressed: _titleController.text.trim().isEmpty ? null : () => _add(cubit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _editSubtask(BuildContext context, TaskDetailCubit cubit, Subtask s) async {
  final titleController = TextEditingController(text: s.title);
  final descController = TextEditingController(text: s.description ?? '');
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editar subtarea', style: AppTextStyles.headline),
            Gaps.vLg,
            AppTextField(label: 'Título', controller: titleController, autofocus: true),
            Gaps.vMd,
            AppTextField(
              label: 'Descripción',
              hint: 'Opcional',
              controller: descController,
              maxLines: 3,
            ),
            Gaps.vXl,
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                Gaps.hSm,
                Expanded(
                  child: PrimaryButton(
                    label: 'Guardar',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (result == true) {
    cubit.updateSubtask(s.id, title: titleController.text, description: descController.text);
  }
}
