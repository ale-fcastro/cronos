# Cronos

Sistema operativo personal del tiempo. App Flutter (Android/iOS) con tema
oscuro, tipografías IBM Plex y persistencia local en SQLite.

## Qué hace

- **Hoy**: score del día (cumplimiento, eficiencia, sueño, puntualidad — pesos
  configurables), tiempo productivo/perdido, tarea o actividad en curso con
  cronómetro vivo, siguiente bloque y score de los últimos 7 días.
- **Agenda**: línea de tiempo del día (tareas planificadas, actividades,
  eventos y huecos libres) y mapa de calor mensual.
- **Tareas**: lista Hoy/Semana/Todas con prioridades P1–P3, cronómetro por
  tarea (solo uno a la vez), estimado vs real, detalle con historial de
  sesiones y tareas recurrentes (diarias o por día de semana, con fecha de
  inicio elegible).
- **Registrar** (FAB): tareas con fecha/hora reales, sugerencias del
  historial, vínculo opcional con una app del teléfono para confirmar
  cumplimiento automático; actividades con cronómetro (dormir, comer,
  ejercicio, redes…) y tipos personalizados; eventos imprevistos con
  sugerencias de tu historial.
- **Áreas de vida y proyectos**: clasificación transversal (trabajo, salud,
  finanzas, etc.) y proyectos propios, usados en tareas, actividades y
  eventos para ver en qué invertís el tiempo.
- **Analizar**: métricas, tareas, eventos y uso real del teléfono (requiere
  el permiso "Acceso al uso" de Android) sobre la última semana o mes.
- **Configuración**: horarios editables por día (laboral/estudio/sueño +
  horarios propios), notificaciones de tareas planificadas, aviso opcional
  si te distraés de la tarea en curso, bloqueo con huella/cara/PIN del
  sistema, pesos del score, exportar/backup (CSV, JSON, PDF, backup
  completo restaurable) y una pantalla de soporte con contacto directo.
- **Actualizaciones**: al abrir la app, chequea si hay una versión más nueva
  publicada en GitHub Releases y la descarga e instala sin salir de Cronos.

## Arquitectura

Clean Architecture por feature + BLoC (Cubit) + get_it:

```
lib/
  core/        # DB (sqflite), servicios transversales, DI, navegación, utils
  features/    # dashboard, schedule, tasks, activities, events, metrics,
               # notifications, projects, security, settings
    <feature>/
      data/       # datasources SQLite + repositorios
      domain/     # entidades, contratos, usecases
      presentation/  # cubits + páginas/widgets
  shared/      # design system (tema, widgets)
```

Las features nunca se importan entre sí directamente: lo transversal (timer
compartido, áreas de vida, proyectos, uso del teléfono, actualizaciones)
vive en `core/services/`.

Los datos viven en SQLite (`cronos.db`): `tasks`, `task_sessions`,
`task_recurrences`, `activity_types`, `activity_sessions`,
`pending_activity_interruption`, `events`, `settings`, `life_areas`,
`projects`, `custom_schedules`, `schedule_ranges`. El motor
(`core/analytics/stats_engine.dart`) computa los agregados por día que
alimentan dashboard, agenda y métricas.

## Compilar e instalar

Requisitos: Flutter ≥ 3.27 con Android SDK configurado.

```bash
./build_apk.sh
```

Eso corre `pub get`, `analyze`, `test` y `build apk --release`. El APK queda
en `build/app/outputs/flutter-apk/app-release.apk` (firmado con clave debug:
instalable de inmediato). Con el teléfono por USB:

```bash
flutter install --release
```

## Tests

```bash
flutter test
```

Unitarios de formato/es, del motor de estadísticas, de los datasources
(SQLite en memoria vía `sqflite_common_ffi`) y de migraciones de esquema,
más el smoke test de arranque.

## Privacidad

Todo se guarda solo en el teléfono (SQLite local): no hay cuenta ni
servidor. `Exportar y backup` en Configuración permite sacar los datos
(CSV/JSON/PDF) o hacer una copia completa restaurable.
