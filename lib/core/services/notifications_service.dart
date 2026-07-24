import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';

/// Recordatorios locales de tareas planificadas ("avisos"): sin backend,
/// todo se agenda en el dispositivo con flutter_local_notifications.
///
/// A diferencia del "Acceso al uso" (core/services/app_usage_service.dart),
/// el permiso de notificaciones SÍ tiene un diálogo normal del sistema:
/// pedirlo nunca saca al usuario de la app.
class NotificationsService {
  NotificationsService(this._database, {FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final AppDatabase _database;
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'task_reminders';
  static const _channelName = 'Recordatorios de tareas';
  static const _enabledKey = 'notifications_enabled';

  /// Se invoca al tocar el aviso de una tarea (payload = id de la tarea).
  void Function(String taskId)? onTaskReminderTapped;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      tzdata.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // Sin zona horaria resuelta, sigue en UTC: preferible avisar a una
      // hora corrida que no avisar nunca.
    }
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: darwinInit,
          macOS: darwinInit,
        ),
        onDidReceiveNotificationResponse: (response) {
          final taskId = response.payload;
          if (taskId != null && taskId.isNotEmpty) onTaskReminderTapped?.call(taskId);
        },
      );
    } catch (_) {
      // Plataforma sin soporte (o sin plugin nativo registrado): el resto
      // de la app sigue funcionando sin recordatorios.
    }
  }

  Future<bool> isEnabled() async {
    final db = await _database.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_enabledKey]);
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  /// Activa/desactiva los recordatorios. Al desactivar, cancela todos los
  /// ya agendados (evita avisos huérfanos que el usuario ya no quiere).
  Future<void> setEnabled(bool value) async {
    final db = await _database.database;
    await db.insert(
      'settings',
      {'key': _enabledKey, 'value': value ? '1' : '0'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (!value) {
      try {
        await _plugin.cancelAll();
      } catch (_) {}
    }
  }

  Future<bool> hasPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final perms = await ios?.checkPermissions();
        return perms?.isEnabled ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macos = _plugin
            .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
        final perms = await macos?.checkPermissions();
        return perms?.isEnabled ?? false;
      }
      return true; // Escritorio (Linux/Windows): sin permiso que pedir.
    } catch (_) {
      return false;
    }
  }

  /// Pide el permiso con el diálogo normal del sistema (Android 13+ /
  /// iOS / macOS). No-op en plataformas donde no aplica.
  Future<bool> requestPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macos = _plugin
            .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
        return await macos?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  int _notificationId(String taskId) => taskId.hashCode & 0x7fffffff;

  /// Agenda un aviso para cuando empiece la tarea [taskId]. No-op si los
  /// recordatorios están desactivados, sin permiso, o si [at] ya pasó.
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    String? project,
    required DateTime at,
  }) async {
    if (at.isBefore(DateTime.now())) return;
    if (!await isEnabled() || !await hasPermission()) return;
    await initialize();
    try {
      await _plugin.zonedSchedule(
        id: _notificationId(taskId),
        title: 'Es hora de: $title',
        body: (project == null || project.isEmpty) ? 'Tocá para abrir la tarea.' : project,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Avisos cuando empieza una tarea planificada',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: taskId,
      );
    } catch (_) {
      // Un aviso perdido no debe romper crear/editar una tarea.
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    try {
      await _plugin.cancel(id: _notificationId(taskId));
    } catch (_) {}
  }

  /// Si la app se abrió tocando un aviso (estaba cerrada), devuelve el id
  /// de la tarea; de lo contrario null. Se consulta una sola vez al arrancar.
  Future<String?> consumeLaunchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp == true) {
        return details?.notificationResponse?.payload;
      }
    } catch (_) {}
    return null;
  }
}
