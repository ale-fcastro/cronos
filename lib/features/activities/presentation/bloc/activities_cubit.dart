import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/diagnostics/error_reporting.dart';
import '../../../../core/services/life_areas_service.dart';
import '../../domain/entities/new_activity_type_input.dart';
import '../../domain/usecases/activities_usecases.dart';
import 'activities_state.dart';

class ActivitiesCubit extends Cubit<ActivitiesState> {
  ActivitiesCubit(
    this._getFrequent,
    this._getTodayLog,
    this._getRunning,
    this._startActivity,
    this._stopRunning,
    this._createActivityType,
    this._deleteActivityType,
    this._lifeAreasService,
  ) : super(const ActivitiesState()) {
    _load();
    _loadLifeAreas();
    // Refresca el cronómetro de la actividad en curso cada segundo.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (state.running == null) return;
      final running = await _getRunning();
      if (isClosed) return;
      emit(state.copyWith(running: running, clearRunning: running == null));
    });
  }

  final GetFrequentActivities _getFrequent;
  final GetTodayActivityLog _getTodayLog;
  final GetRunningActivity _getRunning;
  final StartActivity _startActivity;
  final StopRunningActivity _stopRunning;
  final CreateActivityType _createActivityType;
  final DeleteActivityType _deleteActivityType;
  final LifeAreasService _lifeAreasService;
  Timer? _ticker;

  Future<void> _load() async {
    try {
      final activities = await _getFrequent();
      final log = await _getTodayLog();
      final running = await _getRunning();
      if (isClosed) return;
      emit(state.copyWith(activities: activities, log: log, running: running));
    } catch (e, st) {
      reportError('ActivitiesCubit._load', e, st);
    }
  }

  Future<void> _loadLifeAreas() async {
    try {
      final areas = await _lifeAreasService.getAll();
      if (isClosed) return;
      emit(state.copyWith(lifeAreas: areas));
    } catch (e, st) {
      reportError('ActivitiesCubit._loadLifeAreas', e, st);
    }
  }

  Future<void> start(String activityId) async {
    await _startActivity(activityId);
    await _load();
  }

  Future<void> stop() async {
    await _stopRunning();
    final activities = await _getFrequent();
    final log = await _getTodayLog();
    if (isClosed) return;
    emit(state.copyWith(activities: activities, log: log, clearRunning: true));
  }

  Future<void> createActivityType(NewActivityTypeInput input) async {
    try {
      await _createActivityType(input);
      await _load();
    } catch (e, st) {
      reportError('ActivitiesCubit.createActivityType', e, st);
    }
  }

  Future<void> removeActivityType(String id) async {
    try {
      await _deleteActivityType(id);
      await _load();
    } catch (e, st) {
      reportError('ActivitiesCubit.removeActivityType', e, st);
    }
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
