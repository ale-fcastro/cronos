# Cronos

Sistema operativo personal del tiempo. App Flutter (Android/iOS) con tema
oscuro, tipografías IBM Plex y persistencia local en SQLite.

## Qué hace

- **Hoy**: score del día (cumplimiento, eficiencia, sueño, puntualidad — pesos
  configurables), tiempo productivo/perdido, tarea o actividad en curso con
  cronómetro vivo, siguiente bloque y score de los últimos 7 días.
- **Agenda**: línea de tiempo del día (tareas planificadas, actividades,
  eventos y huecos libres) y mapa de calor mensual — tocando cualquier día
  del mes se abre su agenda real, no solo el score. También se puede
  importar un calendario externo (p.ej. un .ics exportado de Google
  Calendar) para traer eventos próximos como tareas; importación manual
  desde un archivo, de solo lectura, no trae eventos recurrentes.
- **Avisos de vencimiento**: si una tarea planificada pasa su hora sin
  arrancarse, Croni avisa una vez por notificación (chequeo periódico en
  segundo plano, cada 15 minutos).
- **Tareas**: lista Hoy/Semana/Todas con prioridades P1–P3, cronómetro por
  tarea (solo uno a la vez), estimado vs real, detalle con historial de
  sesiones, subtareas (checklist que bloquea finalizar hasta completarse) y
  tareas recurrentes (diarias o por día de semana, con fecha de inicio
  elegible). Finalizar no es un toque sin más: Cronos pregunta si la tarea
  se hizo de verdad — pide el horario real si nunca se usó el cronómetro,
  o un motivo si en realidad no se hizo (queda como "no hecha", no
  desaparece en silencio).
- **Registrar** (FAB): tareas con fecha/hora reales, sugerencias del
  historial, vínculo opcional con una app del teléfono para confirmar
  cumplimiento automático; actividades con cronómetro (dormir, comer,
  ejercicio, redes…) y tipos personalizados; eventos imprevistos con
  sugerencias de tu historial.
- **Áreas de vida y proyectos**: clasificación transversal (trabajo, salud,
  finanzas, etc., editable por completo — crear, renombrar/recolorear y
  borrar) y proyectos propios, usadas en tareas, actividades y eventos
  para ver en qué invertís el tiempo.
- **Categorías de actividad**: cada una se marca como productiva, de ocio
  o neutra — así el cálculo de tiempo productivo/perdido y el score saben
  qué hacer con cualquier actividad, no solo con las que trae la app de
  fábrica. Se editan desde Configuración → Categorías o manteniendo
  presionada una tarjeta al registrar.
- **Analizar**: métricas, tareas, eventos y uso real del teléfono (requiere
  el permiso "Acceso al uso" de Android) sobre la última semana o mes.
  Incluye un botón discreto para compartir un resumen de texto de tus
  datos con la IA que ya tengas instalada (Gemini, ChatGPT...) vía el
  selector de compartir de Android — Cronos no tiene IA propia ni llama a
  ninguna API: arma el contexto, el usuario elige a quién dárselo. Ver
  `features/metrics/domain/services/ai_summary_service.dart`.
- **Configuración**: horarios editables por día (laboral/estudio/sueño +
  horarios propios), notificaciones de tareas planificadas, aviso opcional
  si te distraés de la tarea en curso, bloqueo con huella/cara/PIN del
  sistema, pesos del score, exportar/backup (CSV, JSON, PDF, backup
  completo restaurable) y una pantalla de soporte con contacto directo.
- **Actualizaciones**: al abrir la app, chequea si hay una versión más nueva
  publicada en GitHub Releases y la descarga e instala sin salir de Cronos;
  también avisa por notificación.
- **Croni**: la mascota de la app (guía de bienvenida, tour de la primera
  vez) también firma los avisos — recordatorios, hitos y notificaciones de
  actualización hablan como Croni, no como "Cronos" a secas.

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

## Publicar una versión

El chequeo de actualizaciones (`core/services/app_update_service.dart`)
apunta al último release público de este repo en GitHub. Para publicar una
nueva versión:

```bash
# 1. Subí version en pubspec.yaml (x.y.z+build)
export PATH="$HOME/flutter/bin:$PATH" ANDROID_HOME=/opt/android-sdk ANDROID_SDK_ROOT=/opt/android-sdk
flutter build apk --release

# 2. Commit + tag (el tag debe ser "vX.Y.Z", igual al de pubspec.yaml)
git add -A && git commit -m "..."
git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin main vX.Y.Z

# 3. Publicar el release con el APK adjunto
gh release create vX.Y.Z build/app/outputs/flutter-apk/app-release.apk \
  --title "Cronos vX.Y.Z" --notes "..."
```

El repo tiene que estar público (o el endpoint `releases/latest` de la API
de GitHub no responde sin autenticación, y ningún teléfono va a detectar la
actualización).

**Las notas del release (`--notes`) no son solo para GitHub**: son
exactamente lo que `AppUpdateService.checkWhatsNew()` muestra en el cartel
"Croni te cuenta las novedades" la primera vez que alguien abre la app
después de actualizar (ver [whats_new_dialog.dart](lib/shared/widgets/dialogs/whats_new_dialog.dart)).
Ese cartel sale una sola vez por versión instalada — nunca se repite ni se
puede volver a abrir a mano — así que las notas tienen que estar escritas
para el usuario final (qué cambió, en criollo, sin jerga técnica ni notas
de desarrollo tipo "build de prueba"), no como un changelog de commits.
**Esto hay que actualizarlo con cada versión que se publica**, sin excepción.
Además, actualizá siempre `Guia_de_Uso_Cronos.pdf` con lo que haya cambiado
antes de compilar el release (ver el PDF para más detalle de cada pantalla).

## Autor

Hecho por Francisco Castro, desarrollador de software independiente.
