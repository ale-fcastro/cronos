import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/activities_usecases.dart';
import 'activities_state.dart';

class ActivitiesCubit extends Cubit<ActivitiesState> {
  ActivitiesCubit(
    this._getFrequent,
    this._getTodayLog,
    this._getRunning,
    this._startActivity,
    this._stopRunning,
  ) : super(const ActivitiesState()) {
    _load();
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
  Timer? _ticker;

  Future<void> _load() async {
    final activities = await _getFrequent();
    final log = await _getTodayLog();
    final running = await _getRunning();
    if (isClosed) return;
    emit(state.copyWith(activities: activities, log: log, running: running));
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

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
