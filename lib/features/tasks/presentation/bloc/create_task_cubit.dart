import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/models/linked_app_option.dart';
import '../../../../core/services/app_usage_service.dart';
import '../../../../core/services/life_areas_service.dart';
import '../../../../core/services/projects_service.dart';
import '../../domain/entities/new_task_input.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_recurrence.dart';
import '../../domain/entities/task_suggestion.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/edit_task.dart';
import '../../domain/usecases/search_task_suggestions.dart';
import '../../domain/usecases/task_recurrence_usecases.dart';
import 'create_task_state.dart';

class CreateTaskCubit extends Cubit<CreateTaskState> {
  CreateTaskCubit(
    this._createTask,
    this._updateTask,
    this._getTaskEditData,
    this._searchSuggestions,
    this._lifeAreasService,
    this._projectsService,
    this._createRecurrence,
    this._generateRecurringTasks,
    this._appUsage, [
    this._editingTaskId,
  ]) : super(const CreateTaskState()) {
    _loadOptions();
    if (_editingTaskId != null) {
      _loadForEdit(_editingTaskId);
    } else {
      _runSearch();
    }
  }

  final CreateTask _createTask;
  final UpdateTask _updateTask;
  final GetTaskEditData _getTaskEditData;
  final SearchTaskSuggestions _searchSuggestions;
  final LifeAreasService _lifeAreasService;
  final ProjectsService _projectsService;
  final CreateTaskRecurrence _createRecurrence;
  final GenerateRecurringTasks _generateRecurringTasks;
  final AppUsageService _appUsage;
  final String? _editingTaskId;

  bool get appLinkSupported => _appUsage.isSupported;

  /// true si el formulario edita una tarea existente en vez de crear una.
  bool get isEditing => _editingTaskId != null;

  Future<void> _loadForEdit(String id) async {
    try {
      final input = await _getTaskEditData(id);
      if (isClosed) return;
      final plannedAt = input.plannedAt;
      emit(state.copyWith(
        title: input.title,
        project: input.project,
        priority: input.priority,
        areaId: input.areaId,
        clearAreaId: input.areaId == null,
        plannedDate: plannedAt,
        plannedMinuteOfDay: plannedAt == null ? null : plannedAt.hour * 60 + plannedAt.minute,
        estimateMinutes: input.estimateMinutes,
        notes: input.notes ?? '',
        linkedPackage: input.linkedPackage,
        linkedAppName: input.linkedAppName,
        clearLinkedApp: input.linkedPackage == null,
      ));
    } catch (e, st) {
      reportError('CreateTaskCubit._loadForEdit', e, st);
    }
  }

  Future<void> _loadOptions() async {
    try {
      final areas = await _lifeAreasService.getAll();
      final names = await _projectsService.getProjectNames();
      if (isClosed) return;
      emit(state.copyWith(
        lifeAreas: areas,
        projectNames: names.isEmpty ? state.projectNames : names,
      ));
    } catch (e, st) {
      reportError('CreateTaskCubit._loadOptions', e, st);
    }
  }

  void setTitle(String v) {
    emit(state.copyWith(title: v));
    _runSearch();
  }

  Future<void> _runSearch() async {
    try {
      final results = await _searchSuggestions(state.title);
      if (isClosed) return;
      emit(state.copyWith(suggestions: results));
    } catch (e, st) {
      reportError('CreateTaskCubit._runSearch', e, st);
    }
  }

  /// Precarga el formulario con la última configuración de esa tarea.
  void applySuggestion(TaskSuggestion s) {
    emit(state.copyWith(
      title: s.title,
      project: s.project,
      priority: s.priority,
      estimateMinutes: s.estimateMinutes,
    ));
    _runSearch();
  }

  void setProject(String v) => emit(state.copyWith(project: v));
  void setArea(String? areaId) => emit(
      areaId == null ? state.copyWith(clearAreaId: true) : state.copyWith(areaId: areaId));
  void setPriority(TaskPriority v) => emit(state.copyWith(priority: v));
  void setNotes(String v) => emit(state.copyWith(notes: v));
  void setDate(DateTime v) => emit(state.copyWith(plannedDate: v));
  void setTime(int hour, int minute) =>
      emit(state.copyWith(plannedMinuteOfDay: hour * 60 + minute));
  void incrementEstimate() =>
      emit(state.copyWith(estimateMinutes: state.estimateMinutes + 15));
  void decrementEstimate() => emit(
      state.copyWith(estimateMinutes: (state.estimateMinutes - 15).clamp(15, 24 * 60)));

  void setRepeatMode(RecurrenceMode? mode) => emit(
      mode == null ? state.copyWith(clearRepeatMode: true) : state.copyWith(repeatMode: mode));

  void setRepeatSameTime(int hour, int minute) =>
      emit(state.copyWith(repeatSameTimeMinuteOfDay: hour * 60 + minute));

  /// Activa/desactiva un día de la semana (1=lunes..7=domingo) para el modo
  /// "por día de semana", con una hora por defecto si se está activando.
  void toggleRepeatWeekday(int weekday, {int defaultMinuteOfDay = 540}) {
    final map = Map<int, int>.from(state.repeatWeekdayMinuteOfDay);
    if (map.containsKey(weekday)) {
      map.remove(weekday);
    } else {
      map[weekday] = defaultMinuteOfDay;
    }
    emit(state.copyWith(repeatWeekdayMinuteOfDay: map));
  }

  void setRepeatWeekdayTime(int weekday, int hour, int minute) {
    final map = Map<int, int>.from(state.repeatWeekdayMinuteOfDay);
    map[weekday] = hour * 60 + minute;
    emit(state.copyWith(repeatWeekdayMinuteOfDay: map));
  }

  Future<bool> hasAppUsagePermission() => _appUsage.hasPermission();

  Future<void> requestAppUsagePermission() => _appUsage.requestPermission();

  /// Apps usadas en los últimos 30 días, para elegir cuál vincular.
  Future<List<LinkedAppOption>> loadAppOptions() {
    final now = DateTime.now();
    return _appUsage.queryUsage(now.subtract(const Duration(days: 30)), now);
  }

  void setLinkedApp(LinkedAppOption? app) => emit(app == null
      ? state.copyWith(clearLinkedApp: true)
      : state.copyWith(linkedPackage: app.packageName, linkedAppName: app.appName));

  Future<void> submit() async {
    if (!state.canSubmit || state.submitting) return;
    emit(state.copyWith(submitting: true));
    try {
      final title = state.title.trim();
      final notes = state.notes.trim().isEmpty ? null : state.notes.trim();

      if (isEditing) {
        await _updateTask(
          _editingTaskId!,
          NewTaskInput(
            title: title,
            project: state.project,
            areaId: state.areaId,
            priority: state.priority,
            plannedAt: state.plannedAt,
            estimateMinutes: state.estimateMinutes,
            notes: notes,
            linkedPackage: state.linkedPackage,
            linkedAppName: state.linkedAppName,
          ),
        );
      } else if (state.repeatMode == null) {
        await _createTask(NewTaskInput(
          title: title,
          project: state.project,
          areaId: state.areaId,
          priority: state.priority,
          plannedAt: state.plannedAt,
          estimateMinutes: state.estimateMinutes,
          notes: notes,
          linkedPackage: state.linkedPackage,
          linkedAppName: state.linkedAppName,
        ));
      } else {
        await _createRecurrence(NewTaskRecurrenceInput(
          title: title,
          project: state.project,
          areaId: state.areaId,
          priority: state.priority,
          estimateMinutes: state.estimateMinutes,
          notes: notes,
          mode: state.repeatMode!,
          sameTimeMinuteOfDay: state.repeatSameTimeMinuteOfDay,
          weekdayMinuteOfDay: state.repeatWeekdayMinuteOfDay,
        ));
        await _generateRecurringTasks();
      }
      if (isClosed) return;
      emit(state.copyWith(submitting: false, submitted: true));
    } catch (e, st) {
      reportError('CreateTaskCubit.submit', e, st);
      if (!isClosed) emit(state.copyWith(submitting: false));
    }
  }
}
