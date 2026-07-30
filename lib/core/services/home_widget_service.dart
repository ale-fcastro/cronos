import 'dart:async';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../../features/dashboard/domain/entities/dashboard_summary.dart';
import '../../features/dashboard/domain/usecases/get_today_summary.dart';
import '../../features/habits/domain/usecases/habits_usecases.dart';
import 'timer_service.dart';

/// Empuja el estado de la app a los widgets de home screen de Android.
/// Vive en core/ porque lo dispara el cronómetro (transversal a
/// tasks/activities) y lo consume el dashboard — no pertenece a una sola
/// feature.
///
/// El refresco es 100% event-driven (vía [TimerService.events]); los
/// widgets nativos no declaran `updatePeriodMillis` propio.
class HomeWidgetService {
  HomeWidgetService(this._timer, this._getTodaySummary, this._getHabits);

  /// Nombre de la tarea periódica de WorkManager que cubre el rollover de
  /// medianoche (el score de "Hoy" cambia con el simple paso del tiempo, sin
  /// que el usuario toque nada) — ver [homeWidgetRefreshCallback] en
  /// main.dart, que la ejecuta con sus propias instancias en otro isolate.
  static const refreshTaskName = 'homeWidgetRefresh';

  final TimerService _timer;
  final GetTodaySummary _getTodaySummary;
  final GetHabits _getHabits;

  StreamSubscription<TimerEventKind>? _sub;

  static const _homeProvider =
      'com.example.cronos.widgets.HomeWidgetProvider';
  static const _sessionProvider =
      'com.example.cronos.widgets.SessionWidgetProvider';
  static const _weeklyProvider =
      'com.example.cronos.widgets.WeeklyWidgetProvider';
  static const _habitsProvider =
      'com.example.cronos.widgets.HabitsWidgetProvider';

  Future<void> start() async {
    await _pushToday();
    await _pushWeekly();
    await _pushSession();
    await _pushHabits();
    _sub = _timer.events.listen((_) async {
      await _pushSession();
      await _pushToday();
      await _pushWeekly();
      // Los hábitos no dependen del cronómetro, pero completar/marcar una
      // tarea no cambia hábitos -- se refresca igual acá por simplicidad, es
      // una consulta liviana y mantiene todos los widgets en sync a la vez.
      await _pushHabits();
    });
  }

  void dispose() => _sub?.cancel();

  /// Los cambios de hábitos (check diario, alta, baja) no pasan por
  /// [TimerService], así que HabitsCubit llama esto directo después de
  /// mutar. Sin guarda de plataforma acá adentro este método rompería en
  /// desktop/iOS, donde HabitsCubit también corre pero no hay plugin nativo.
  Future<void> refreshHabits() async {
    if (!Platform.isAndroid) return;
    await _pushHabits();
  }

  Future<void> _pushToday() async {
    final summary = await _getTodaySummary();
    await HomeWidget.saveWidgetData('today_score', summary.score);
    await HomeWidget.saveWidgetData(
        'today_productive_label', summary.productiveLabel);
    await HomeWidget.saveWidgetData('today_lost_label', summary.lostLabel);
    await HomeWidget.saveWidgetData(
        'today_date_label', summary.dateLabel);
    await HomeWidget.saveWidgetData(
        'today_next_task_title', summary.nextTask?.title ?? '');
    await HomeWidget.saveWidgetData(
        'today_next_task_time', summary.nextTask?.time ?? '');
    await HomeWidget.updateWidget(qualifiedAndroidName: _homeProvider);
  }

  Future<void> _pushWeekly() async {
    final summary = await _getTodaySummary();
    final scores = summary.weeklyScores;
    await HomeWidget.saveWidgetData(
        'weekly_scores', scores.map((p) => p.value.toStringAsFixed(2)).join(','));
    await HomeWidget.saveWidgetData(
        'weekly_labels', scores.map((p) => p.label).join(','));
    await HomeWidget.updateWidget(qualifiedAndroidName: _weeklyProvider);
  }

  Future<void> _pushSession() async {
    final summary = await _getTodaySummary();
    final current = summary.currentTask;
    await HomeWidget.saveWidgetData('session_active', current != null);
    await HomeWidget.saveWidgetData('session_title', current?.title ?? '');
    await HomeWidget.saveWidgetData(
        'session_subtitle', current?.subtitle ?? '');
    await HomeWidget.saveWidgetData(
        'session_started_at_epoch_ms', current?.startedAtEpochMs ?? 0);
    await HomeWidget.saveWidgetData(
        'session_kind', current?.kind == CurrentTrackKind.activity ? 'activity' : 'task');
    await HomeWidget.saveWidgetData(
        'session_task_id',
        current?.kind == CurrentTrackKind.task ? current!.id : '');
    await HomeWidget.updateWidget(qualifiedAndroidName: _sessionProvider);
  }

  /// El widget solo tiene lugar para unos pocos hábitos: se muestran los
  /// más recientes (orden que ya trae [GetHabits]).
  static const _maxHabitsInWidget = 5;

  Future<void> _pushHabits() async {
    final habits = (await _getHabits()).take(_maxHabitsInWidget).toList();
    await HomeWidget.saveWidgetData('habits_count', habits.length);
    for (var i = 0; i < _maxHabitsInWidget; i++) {
      if (i < habits.length) {
        final item = habits[i];
        await HomeWidget.saveWidgetData('habit_${i}_id', item.habit.id);
        await HomeWidget.saveWidgetData('habit_${i}_title', item.habit.title);
        await HomeWidget.saveWidgetData('habit_${i}_done_today', item.doneToday);
        await HomeWidget.saveWidgetData('habit_${i}_streak', item.streak);
      } else {
        await HomeWidget.saveWidgetData('habit_${i}_title', '');
      }
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: _habitsProvider);
  }
}
