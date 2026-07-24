# Cronos

Sistema operativo personal del tiempo. App Flutter (Android/iOS) con tema
oscuro, tipografías IBM Plex y persistencia local en SQLite.

## Qué hace

- **Hoy**: score del día (cumplimiento 40 · eficiencia 30 · sueño 20 ·
  puntualidad 10), tiempo productivo/perdido, tarea en curso con cronómetro
  vivo, siguiente bloque y score semanal — todo calculado desde tus datos.
- **Agenda**: línea de tiempo del día (tareas planificadas, actividades,
  eventos y huecos libres) y mapa de calor mensual.
- **Tareas**: lista Hoy/Semana/Todas con prioridades P1–P3, cronómetro por
  tarea (solo uno a la vez), estimado vs real y detalle con historial de
  sesiones.
- **Registrar** (FAB): tareas con fecha/hora reales (date & time pickers),
  actividades con cronómetro (dormir, comer, ejercicio, redes…) y eventos
  imprevistos con sugerencias de tu historial.
- **Seguridad**: bloqueo opcional al abrir la app con huella/cara/PIN del
  sistema (se activa en Configuración → Seguridad).
- **Analizar**: KPIs, distribución del tiempo, desviación de estimaciones por
  proyecto, ritmo de cierre y costo de imprevistos, sobre los últimos 7 días.

## Arquitectura

Clean Architecture por feature + BLoC (Cubit) + get_it:

```
lib/
  core/        # DB (sqflite), motor de estadísticas, DI, navegación, utils
  features/    # dashboard, schedule, tasks, activities, events, metrics, settings
    <feature>/
      data/       # datasources SQLite + repositorios
      domain/     # entidades, contratos, usecases
      presentation/  # cubits + páginas/widgets
  shared/      # design system (tema, widgets)
```

Los datos viven en SQLite (`cronos.db`): `tasks`, `task_sessions`,
`activity_types`, `activity_sessions`, `events`, `settings`. El motor
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

Unitarios de formato/es, del motor de estadísticas y del datasource de tareas
(SQLite en memoria vía `sqflite_common_ffi`), más el smoke test de arranque.

## Pendiente (v2)

- Editar configuración desde la UI (horarios, pesos del score).
- Seguimiento de uso del teléfono (requiere permiso `UsageStats` de Android).
- Proyectos personalizados (hoy: Personal / Trabajo / Estudio).
