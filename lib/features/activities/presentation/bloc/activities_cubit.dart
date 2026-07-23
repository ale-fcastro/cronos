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
  }

  final GetFrequentActivities _getFrequent;
  final GetTodayActivityLog _getTodayLog;
  final GetRunningActivity _getRunning;
  final StartActivity _startActivity;
  final StopRunningActivity _stopRunning;

  Future<void> _load() async {
    final activities = await _getFrequent();
    final log = await _getTodayLog();
    final running = await _getRunning();
    emit(state.copyWith(activities: activities, log: log, running: running));
  }

  Future<void> start(String activityId) async {
    await _startActivity(activityId);
    final running = await _getRunning();
    emit(state.copyWith(running: running));
  }

  Future<void> stop() async {
    await _stopRunning();
    emit(state.copyWith(clearRunning: true));
  }
}
