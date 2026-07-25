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
    this._appUsage,
    this._checkScheduleConflict,
    this._updateRecurrenceTime, [
    this._editingTaskId,
  ]) : super(const CreateTaskState()) {
    _loadOptions();
    if (_editingTaskId != null) {
      _loadForEdit(_editingTaskId);
    } else {
      _runSearch();
      _checkConflict();
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
  final CheckScheduleConflict _checkScheduleConflict;
  final UpdateTaskRecurrenceTime _updateRecurrenceTime;
  final String? _editingTaskId;

  String? _originalRecurrenceId;
  int? _originalMinuteOfDay;

  bool get appLinkSupported => _appUsage.isSupported;

  /// true si el formulario edita una tarea existente en vez de crear una.
  bool get isEditing => _editingTaskId != null;

  /// true si la tarea editada es una ocurrencia materializada de una regla
  /// de repetición (en vez de una tarea suelta).
  bool get isRecurringInstance => _originalRecurrenceId != null;

  /// true si, editando una ocurrencia de una repetición, la hora elegida
  /// difiere de la original: hay que preguntar si propagarla a la regla.
  bool get changesRecurrenceTime =>
      isRecurringInstance &&
      state.plannedMinuteOfDay != null &&
      state.plannedMinuteOfDay != _originalMinuteOfDay;

  Future<void> _loadForEdit(String id) async {
    try {
      final input = await _getTaskEditData(id);
      if (isClosed) return;
      final plannedAt = input.plannedAt;
      _originalRecurrenceId = input.recurrenceId;
      _originalMinuteOfDay = plannedAt == null ? null : plannedAt.hour * 60 + plannedAt.minute;
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
      await _checkConflict();
    } catch (e, st) {
      reportError('CreateTaskCubit._loadForEdit', e, st);
    }
  }

  /// Revisa si la fecha/hora actual choca con otra tarea. Solo aplica a
  /// tareas sueltas: las reglas de repetición generan varias fechas futuras
  /// y no tienen una única hora "a chequear" en el momento de crearlas.
  Future<void> _checkConflict() async {
    if (state.repeatMode != null) {
      if (state.timeConflict) emit(state.copyWith(timeConflict: false));
      return;
    }
    try {
      final conflict =
          await _checkScheduleConflict(state.plannedAt, excludeTaskId: _editingTaskId);
      if (isClosed) return;
      emit(state.copyWith(timeConflict: conflict));
    } catch (e, st) {
      reportError('CreateTaskCubit._checkConflict', e, st);
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
  void setDate(DateTime v) {
    emit(state.copyWith(plannedDate: v));
    _checkConflict();
  }

  void setTime(int hour, int minute) {
    emit(state.copyWith(plannedMinuteOfDay: hour * 60 + minute));
    _checkConflict();
  }

  void incrementEstimate() =>
      emit(state.copyWith(estimateMinutes: state.estimateMinutes + 15));
  void decrementEstimate() => emit(
      state.copyWith(estimateMinutes: (state.estimateMinutes - 15).clamp(15, 24 * 60)));

  void setRepeatMode(RecurrenceMode? mode) {
    emit(mode == null ? state.copyWith(clearRepeatMode: true) : state.copyWith(repeatMode: mode));
    _checkConflict();
  }

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

  void setRepeatStartDate(DateTime v) => emit(state.copyWith(repeatStartDate: v));

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

  /// [alsoUpdateRecurrence] solo importa si [changesRecurrenceTime]: true
  /// propaga la nueva hora a la regla (para ese día de semana), false deja
  /// la regla como está y el cambio queda solo en esta ocurrencia.
  Future<void> submit({bool alsoUpdateRecurrence = false}) async {
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
        if (changesRecurrenceTime && alsoUpdateRecurrence) {
          await _updateRecurrenceTime(
            _originalRecurrenceId!,
            weekday: state.plannedAt.weekday,
            minuteOfDay: state.plannedMinuteOfDay!,
          );
        }
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
          startDate: state.effectiveRepeatStartDate,
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
