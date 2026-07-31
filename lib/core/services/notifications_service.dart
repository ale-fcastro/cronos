import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
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
  static const _updatesChannelId = 'app_updates';
  static const _updatesChannelName = 'Actualizaciones';
  static const _enabledKey = 'notifications_enabled';

  /// Ícono monocromo de la barra de estado (un ícono a color, como el
  /// launcher, se ve como un cuadrado relleno en Android 5+). Mismo acento
  /// que el resto de la app, para que la notificación se sienta de Croni.
  static const _smallIcon = '@drawable/ic_stat_croni';
  static const _accentColor = Color(0xFF9DB1F5);

  /// Se invoca al tocar el aviso de que una tarea planificada está por
  /// empezar (payload = id de la tarea).
  void Function(String taskId)? onTaskReminderTapped;

  /// Se invoca al tocar el aviso de que una tarea se venció sin arrancarse.
  /// Distinto de [onTaskReminderTapped]: acá conviene preguntar directo
  /// "¿Hiciste [tarea]?" en vez de solo abrir el detalle a esperar.
  void Function(String taskId)? onTaskOverdueTapped;

  /// Se invoca al tocar el aviso de actualización disponible.
  void Function()? onUpdateNotificationTapped;

  /// Payload de la notificación de actualización: distingue el tap de un
  /// recordatorio de tarea (que manda el id de la tarea como payload).
  static const updatePayload = 'app_update';

  /// Prefijo del payload de un aviso de tarea vencida, para distinguirlo
  /// del payload de un recordatorio normal (que es el id de tarea a secas).
  static const overduePayloadPrefix = 'overdue:';

  /// Prefijo del payload de la notificación de desambiguación de App
  /// Tracking (ver [showAppClassificationPrompt]) — el resto del payload es
  /// el package de la app. Las acciones (qué categoría eligió, o "ignorar")
  /// se resuelven en background: ver `notificationBackgroundResponseHandler`
  /// en main.dart, registrado como [onDidReceiveBackgroundNotificationResponse]
  /// más abajo.
  static const appTrackPayloadPrefix = 'apptrack:';

  /// Id de la acción "ignorar esta app" en [showAppClassificationPrompt].
  static const appTrackIgnoreActionId = 'ignore';

  /// Prefijo del id de acción con la categoría elegida en
  /// [showAppClassificationPrompt] — el resto es el id del ActivityType.
  static const appTrackActivityActionPrefix = 'activity:';

  /// [onBackgroundResponse] registra el handler global de acciones que se
  /// resuelven sin abrir la app (hoy solo las de
  /// [showAppClassificationPrompt]) — flutter_local_notifications solo
  /// admite UNO por app, así que solo el arranque principal en main.dart lo
  /// pasa; instancias descartables (p.ej. la de `nudgeCallbackDispatcher`,
  /// que solo necesita `showNow`) lo dejan en null.
  Future<void> initialize({
    void Function(NotificationResponse)? onBackgroundResponse,
  }) async {
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
    const androidInit = AndroidInitializationSettings(_smallIcon);
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
          final payload = response.payload;
          if (payload == updatePayload) {
            onUpdateNotificationTapped?.call();
            return;
          }
          if (payload == null || payload.isEmpty) return;
          if (payload.startsWith(overduePayloadPrefix)) {
            onTaskOverdueTapped?.call(payload.substring(overduePayloadPrefix.length));
            return;
          }
          if (payload.startsWith(appTrackPayloadPrefix)) {
            // El tap del cuerpo (no de una acción) no hace nada especial acá
            // -- las acciones de esta notificación son todas
            // showsUserInterface:false y se resuelven en background.
            return;
          }
          onTaskReminderTapped?.call(payload);
        },
        onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
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
        title: 'Croni te avisa: $title',
        body: (project == null || project.isEmpty) ? 'Tocá para abrir la tarea.' : project,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Avisos cuando empieza una tarea planificada',
            icon: _smallIcon,
            color: _accentColor,
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

  /// Notificación inmediata (no agendada), p.ej. un hito como la primera
  /// tarea creada. Respeta el mismo apagado/permiso que los recordatorios.
  Future<void> showNow(String title, String body) async {
    if (!await isEnabled() || !await hasPermission()) return;
    await initialize();
    try {
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            icon: _smallIcon,
            color: _accentColor,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Un aviso perdido no debe romper el flujo que lo dispara.
    }
  }

  /// Avisa que una tarea planificada venció sin arrancarse. Mismo gate que
  /// los recordatorios de "empieza ahora" (isEnabled/hasPermission) y mismo
  /// canal. El payload lleva [overduePayloadPrefix] para que, al tocarlo,
  /// [onTaskOverdueTapped] pregunte directo "¿Hiciste [tarea]?" en vez de
  /// solo abrir el detalle a esperar (a diferencia de [scheduleTaskReminder]).
  Future<void> showTaskOverdue(String taskId, String title) async {
    if (!await isEnabled() || !await hasPermission()) return;
    await initialize();
    try {
      await _plugin.show(
        id: _notificationId('overdue_$taskId'),
        title: 'Croni te pregunta',
        body: '¿Hiciste "$title"? Tocá para contarme.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            icon: _smallIcon,
            color: _accentColor,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        payload: '$overduePayloadPrefix$taskId',
      );
    } catch (_) {
      // Un aviso perdido no debe romper el chequeo periódico.
    }
  }

  /// Avisa que hay una versión nueva de Cronos, en canal propio: no depende
  /// del interruptor de recordatorios de tareas (son cosas distintas), solo
  /// del permiso general de notificaciones.
  Future<void> showUpdateAvailable(String version) async {
    if (!await hasPermission()) return;
    await initialize();
    try {
      await _plugin.show(
        id: updatePayload.hashCode & 0x7fffffff,
        title: 'Croni te avisa',
        body: 'Cronos $version ya está disponible. Tocá para actualizar.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _updatesChannelId,
            _updatesChannelName,
            channelDescription: 'Avisa cuando hay una nueva versión de Cronos',
            icon: _smallIcon,
            color: _accentColor,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        payload: updatePayload,
      );
    } catch (_) {
      // Un aviso perdido no debe romper el chequeo de actualizaciones.
    }
  }

  /// Pregunta "¿qué estás haciendo en \$appName?" cuando App Tracking no
  /// puede resolver la app sola (sin contexto, o en varios a la vez). No
  /// depende de [isEnabled]/[hasPermission] de los recordatorios de tareas
  /// (es una función aparte); el llamador (AppTrackingResolver) decide si
  /// preguntar. [candidates] son hasta 4 pares (id, nombre) de ActivityType.
  /// [includeIgnoreAction] se omite en el fallback genérico (Trabajo/
  /// Estudio/Ocio/Chequeo rápido): ya son 4 botones, y "Chequeo rápido"
  /// aprendido con el tiempo cumple el mismo rol que "Ignorar" para una app
  /// irrelevante sin agregar un quinto botón (el límite práctico de
  /// Android para que se vean todos).
  Future<void> showAppClassificationPrompt(
    String packageName,
    String appName,
    List<(String id, String name)> candidates, {
    bool includeIgnoreAction = true,
  }) async {
    if (!await hasPermission()) return;
    await initialize();
    try {
      await _plugin.show(
        id: _notificationId('apptrack_$packageName'),
        title: 'Croni te pregunta',
        body: '¿Qué estás haciendo en $appName?',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            icon: _smallIcon,
            color: _accentColor,
            importance: Importance.high,
            priority: Priority.high,
            actions: [
              for (final (id, name) in candidates)
                AndroidNotificationAction(
                  '$appTrackActivityActionPrefix$id',
                  name,
                  showsUserInterface: false,
                ),
              if (includeIgnoreAction)
                const AndroidNotificationAction(
                  appTrackIgnoreActionId,
                  'Ignorar esta app',
                  showsUserInterface: false,
                ),
            ],
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        ),
        payload: '$appTrackPayloadPrefix$packageName',
      );
    } catch (_) {
      // Un aviso perdido no debe romper el sondeo de App Tracking.
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
