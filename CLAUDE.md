# Cronos — reglas de trabajo

Este archivo lo carga automáticamente cualquier sesión de Claude Code que
trabaje en este repo, sea desde esta PC o desde otra. Sirve para no
perder las convenciones que fuimos estableciendo, sesión tras sesión.

## Regla de oro

**No te guíes de lo que "se supone" que se hizo en una sesión anterior —
verificá siempre contra el código real.** Hay trabajo en paralelo (del
usuario, de otras sesiones) que vos no ves. Si algo en este documento no
coincide con lo que encontrás en el código, confiá en el código y avisá
de la diferencia.

## Stack

- Flutter (Android/iOS), Clean Architecture por feature, BLoC/Cubit,
  `get_it` como service locator.
- SQLite vía `sqflite` (dispositivo) / `sqflite_common_ffi` (tests y
  escritorio).
- Repo: `github.com/ale-fcastro/cronos` — **tiene que estar público**,
  el chequeo de actualizaciones in-app pega contra la API de GitHub sin
  autenticación y no responde en repos privados.
- La sesión de `gh` autenticada en esta PC es un colaborador con permiso
  de `push` pero **sin admin** — no puede cambiar visibilidad del repo ni
  settings. Eso lo hace el dueño (`ale-fcastro`) a mano, en GitHub.

## Comandos básicos

```bash
export PATH="$HOME/flutter/bin:$PATH"
flutter pub get
flutter analyze   # 0 issues, salvo el _parseTimeToMinutes ya conocido (info, no error)
flutter test      # todos verdes, siempre, antes de dar algo por terminado
```

Build de release (necesita el Android SDK con licencias aceptadas):

```bash
export ANDROID_HOME=/opt/android-sdk ANDROID_SDK_ROOT=/opt/android-sdk
flutter build apk --release
# Sale en build/app/outputs/flutter-apk/app-release.apk
```

`isMinifyEnabled = false` en `android/app/build.gradle.kts` es
intencional: R8 rompía el `WorkDatabase` generado por Room para
WorkManager. No lo actives sin agregar reglas de keep propias.

## Arquitectura

```
lib/
  core/        # DB, servicios transversales (2+ features), DI, navegación, utils
  features/    # cada una: data/ domain/ presentation/
  shared/      # design system: tema, widgets reusables
```

- Las features **nunca** se importan entre sí directamente.
- Un servicio de negocio que solo usa UNA feature va adentro de esa
  feature (p.ej. `features/metrics/domain/services/`), no en `core/` —
  `core/` es solo para lo genuinamente transversal (usado por 2+
  features). Meter algo feature-specific en `core/` invierte la
  dependencia y rompe la regla de arriba.
- Muchos servicios "de core" (`OnboardingService`, `AppUpdateService`,
  `ExportService`, `LifeAreasService`...) no pasan por la ceremonia
  completa de datasource/repository/usecase: le pegan directo a
  `AppDatabase`. Es un patrón aceptado en este proyecto para servicios
  chicos — no hace falta inventar capas de más.

## Migraciones de base de datos

`lib/core/database/app_database.dart` tiene todo el esquema.

1. Subí `_version`.
2. Agregá la tabla/columna nueva en `_onCreate` (instalación nueva desde
   cero).
3. Agregá un bloque `if (oldVersion < N)` en `_onUpgrade`:
   - Columna nueva en tabla existente → `ALTER TABLE ... ADD COLUMN`
     **guardado** con `_columnExists(db, tabla, columna)` antes.
   - Tabla nueva → creála directo (no hace falta guard si es genuinamente
     nueva), pero si hay un camino donde la tabla ya pudo haberse creado
     en una versión anterior de este mismo bloque de trabajo, chequeá con
     `sqlite_master` antes.
4. `test/core/app_database_migration_test.dart` simula un dispositivo
   real que arrancó en v6 y corre la migración completa hasta la versión
   actual. Si tu `ALTER TABLE` depende de una tabla que ese fixture no
   crea, agregala vos en el fixture (representando lo que un dispositivo
   real en v6 ya tendría — no lo que hace `_onCreate` hoy). Ya pasó dos
   veces que un `ALTER TABLE` nuevo rompía este test porque el fixture
   viejo no incluía esa tabla.

## Testing

- SQLite en memoria: `sqfliteFfiInit()` + `databaseFactoryFfiNoIsolate` +
  `inMemoryDatabasePath` (o un archivo temporal real para tests de
  migración que necesitan reabrir la conexión, como el de arriba).
- Se testea contra datasources/servicios reales insertando filas crudas
  con `db.insert(...)`, no con mocks — salvo para HTTP (`http.Client`),
  ahí sí `package:http/testing.dart`'s `MockClient`.
- Cuando arreglás un bug, si podés, confirmá que el test falla contra el
  código viejo (`git stash` o revirtiendo el fix a mano) antes de
  confirmar que pasa con el fix puesto.
- Cuidado con tests que dependen de "hoy": usar `scope: 'all'` en vez de
  `'week'` si el resultado puede cruzar el límite de fin de semana o de
  mes corriendo el test en un día distinto. Ya pasó más de una vez.
- Antes de escribir lógica nueva de agregación/estadísticas, mirá si ya
  existe un usecase/datasource que compute lo mismo (p.ej. los que usa
  Analizar) y reusalo en vez de duplicar cálculos.

## Publicar una versión

Ver también la sección "Publicar una versión" del README.

1. Subí `version` en `pubspec.yaml` (`x.y.z+build`, build incremental).
2. **Actualizá `Guia_de_Uso_Cronos.pdf`** si agregaste o cambiaste algo
   user-facing (ver abajo) — no es opcional, es una regla fija de este
   proyecto.
3. Actualizá el README si corresponde.
4. `flutter analyze` + `flutter test` limpios.
5. `flutter build apk --release`.
6. Commit + `git tag -a vX.Y.Z -m vX.Y.Z` + push de la rama y del tag.
7. `gh release create vX.Y.Z build/app/outputs/flutter-apk/app-release.apk --title "Cronos vX.Y.Z" --notes "..."`

**Las notas del release no son un changelog técnico.** Son exactamente
lo que `AppUpdateService.checkWhatsNew()` muestra en el cartel "Croni te
cuenta las novedades" la primera vez que alguien abre la app después de
actualizar — un cartel que sale **una sola vez por versión instalada** y
nunca se puede volver a abrir a mano. Escribilas para el usuario final:
en criollo, sin jerga, sin notas de desarrollo ("build de prueba", etc.).
Emojis están bien acá si suman claridad — el usuario los pidió
explícitamente para este cartel.

Esta sesión viene commiteando y pusheando en cada ronda de cambios sin
pedir confirmación explícita cada vez — es el flujo que el usuario
espera en este proyecto puntual (a diferencia de la directiva general de
"solo commitear si se pide explícitamente"). Si en algún momento pide lo
contrario, seguí esa instrucción nueva por encima de esta nota. De
cualquier forma: nunca `--force`, nunca `--no-verify`, nunca `amend`
salvo pedido explícito.

## Guía de usuario (PDF)

`Guia_de_Uso_Cronos.pdf` se genera con `tools/build_user_guide.py`
(reportlab), commiteado en el repo — **no vive solo en un scratchpad
efímero**, así que sigue disponible entre sesiones y máquinas.

```bash
python3 -m venv /tmp/pdfenv
/tmp/pdfenv/bin/pip install reportlab pypdf pillow
/tmp/pdfenv/bin/python tools/build_user_guide.py
```

Después de tocarla, renderizá a PNG las páginas que cambiaste y mirala
antes de dar el cambio por bueno:

```bash
pdftoppm -png -r 100 -f N -l N Guia_de_Uso_Cronos.pdf /tmp/preview
```

Si el script alguna vez se pierde, se puede reconstruir extrayendo el
texto del PDF existente (`pypdf`) y volviendo a armar el layout — pero
evitalo, es mucho más lento que simplemente mantener `tools/build_user_guide.py`
al día.

## Tono de la app (Croni)

Cronos tiene una mascota, Croni (`lib/shared/widgets/mascot/cronos_mascot.dart`,
estados `idle/wave/walk/celebrate/think/sleep`). Los avisos y diálogos de
sistema (notificaciones, actualización, novedades) hablan con su voz
("Croni te avisa...") y, cuando el diálogo lo amerita, la mascota
aparece animada de verdad arriba del título — no alcanza con nombrarla
en el texto.

No vendemos "Cronos tiene IA" como feature principal — ver la función de
compartir resumen con la IA del teléfono en Analizar
(`features/metrics/domain/services/ai_summary_service.dart`): es un
botón discreto + un aviso de una sola vez, nunca un banner permanente ni
texto en la descripción de la app.

## Cosas ya resueltas (no las reinventes)

- **Ícono de notificación**: tiene que ser un drawable monocromo
  (`@drawable/ic_stat_croni`) — un ícono a color como el launcher se ve
  como un cuadrado relleno en Android 5+.
- **Import de calendario**: es por archivo `.ics` elegido a mano
  (`file_picker`), no por URL. La "dirección secreta en formato iCal" de
  Google Calendar es prácticamente indescubrible para un usuario no
  técnico — se probó y se abandonó ese camino.
- **Integración con IA**: no existe (todavía) una API de Android para
  "entregarle datos a la IA del sistema" de forma genérica. Lo que
  funciona hoy es compartir texto estructurado vía el share sheet nativo
  (`share_plus`) y dejar que el usuario elija la app de IA instalada.
- **Hojas de selección genéricas** (`shared/widgets/pickers/selection_sheet.dart`):
  tienen que ser scrolleables (`isScrollControlled: true` +
  `ListView` acotado en altura) — una lista larga (apps instaladas, etc.)
  se corta si no.
- **Finalizar una tarea** no es un toque directo: pasa por
  `showCompleteTaskDialog` (confirmación + horario real si nunca se usó
  el cronómetro, o motivo si no se hizo) y las subtareas pendientes
  bloquean la finalización — ver `features/tasks/presentation/widgets/complete_task_dialog.dart`.
