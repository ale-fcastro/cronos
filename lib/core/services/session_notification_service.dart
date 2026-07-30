import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/dashboard/domain/entities/dashboard_summary.dart';
import '../../features/dashboard/domain/usecases/get_today_summary.dart';
import 'notifications_service.dart';
import 'timer_service.dart';

/// Notificación persistente ("Croni te acompaña") de la tarea/actividad con
/// el cronómetro corriendo, respaldada por un Foreground Service real (ver
/// SessionForegroundService.kt) para que el sistema no trate a Cronos como
/// "en background" mientras hay una sesión activa.
///
/// El texto/chronometer de la notificación los arma este archivo vía
/// flutter_local_notifications (misma fuente de verdad de siempre); el
/// servicio nativo solo la "adopta" para startForeground() y le agrega los
/// botones Pausar/Finalizar, que mutan la base a través del canal de
/// interactividad de home_widget en vez de necesitar un plugin propio (ver
/// sessionActionCallback en main.dart).
class SessionNotificationService {
  SessionNotificationService(
    this._timer,
    this._getTodaySummary,
    this._notifications, {
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final TimerService _timer;
  final GetTodaySummary _getTodaySummary;
  final NotificationsService _notifications;
  final FlutterLocalNotificationsPlugin _plugin;

  StreamSubscription<TimerEventKind>? _sub;

  static const _notificationId = 7001;
  static const _channelId = 'active_session';
  static const _channelName = 'Sesión en curso';
  static const _smallIcon = '@drawable/ic_stat_croni';
  static const _accentColor = Color(0xFF9DB1F5);
  static const _serviceChannel = MethodChannel('cronos/session_service');

  Future<void> start() async {
    _sub = _timer.events.listen((_) => _sync());
    await _sync();
  }

  void dispose() => _sub?.cancel();

  Future<void> _sync() async {
    final summary = await _getTodaySummary();
    final current = summary.currentTask;
    if (current == null) {
      await _stop();
    } else {
      await _show(current);
    }
  }

  Future<void> _show(CurrentTaskInfo current) async {
    if (!await _notifications.hasPermission()) return;
    final details = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Cronómetro de la tarea o actividad en curso.',
      icon: _smallIcon,
      color: _accentColor,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: true,
      usesChronometer: true,
      when: current.startedAtEpochMs,
      category: AndroidNotificationCategory.stopwatch,
    );
    try {
      await _plugin.show(
        id: _notificationId,
        title: 'Croni te acompaña',
        body: current.subtitle.isEmpty
            ? current.title
            : '${current.title} · ${current.subtitle}',
        notificationDetails: NotificationDetails(android: details),
      );
      await _serviceChannel.invokeMethod('startForegroundSession', {
        'notificationId': _notificationId,
        'kind': current.kind == CurrentTrackKind.activity ? 'activity' : 'task',
        'taskId': current.kind == CurrentTrackKind.task ? current.id : null,
      });
    } catch (_) {
      // Si el foreground service no llega a arrancar, la notificación sigue
      // visible igual: solo se pierde el estado "en ejecución" del sistema.
    }
  }

  Future<void> _stop() async {
    try {
      await _serviceChannel.invokeMethod('stopForegroundSession');
    } catch (_) {
      // Nada que limpiar del lado nativo si ya no estaba corriendo.
    }
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (_) {}
  }
}
