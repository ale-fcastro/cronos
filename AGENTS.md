# Repository Guidelines

## Project Structure & Module Organization

Cronos is a Flutter application organized by feature and Clean Architecture. Application code lives in `lib/`: `core/` contains the database, navigation, dependency injection, and services shared by multiple features; `features/<name>/` is split into `data/`, `domain/`, and `presentation/`; and `shared/` contains the theme and reusable widgets. Do not import one feature directly from another—move genuinely cross-feature behavior into `core/`.

Tests mirror those concerns under `test/core/`, `test/features/`, `test/shared/`, and `test/integration/`. Fonts and icons belong in `assets/`. Platform projects are in `android/`, `ios/`, `web/`, `linux/`, `macos/`, and `windows/`. User-guide generation is maintained in `tools/build_user_guide.py`.

## Build, Test, and Development Commands

- `flutter pub get` installs Dart and Flutter dependencies.
- `flutter run` launches the app on a selected device; `./run_debug.sh` first cleans and records logs in `run_log.txt`.
- `flutter analyze` enforces `flutter_lints` and repository lint settings.
- `flutter test` runs the complete unit and widget suite.
- `./verify.sh` runs dependency resolution, analysis, and expanded tests, writing results to `verify_output.txt`.
- `./build_apk.sh` verifies the project and creates `build/app/outputs/flutter-apk/app-release.apk`.

Flutter 3.27 or newer and Dart 3.6 or newer are required.

## Coding Style & Naming Conventions

Use two-space Dart indentation and run `dart format lib test` before submitting. Prefer single quotes, as configured in `analysis_options.yaml`. Name files `snake_case.dart`, types `UpperCamelCase`, and variables/methods `lowerCamelCase`. Keep Cubits, states, pages, and repositories in their corresponding architectural layer. Small cross-cutting services may access `AppDatabase` directly; avoid adding ceremonial layers without a clear boundary.

## Testing Guidelines

Use `flutter_test`; name files `*_test.dart` and group tests by behavior. Database tests should use `sqflite_common_ffi` with in-memory databases, except migrations that must reopen a temporary database. Add regression coverage for bug fixes and update `test/core/app_database_migration_test.dart` whenever schema changes affect upgrade paths. Avoid date-sensitive fixtures tied to “today.” All tests and analysis must pass before completion.

## Commit & Pull Request Guidelines

Recent history follows Conventional Commit prefixes, typically `feat:`, `fix:`, and `docs:`, followed by a concise Spanish description. Keep commits focused. Pull requests should explain the user-visible change, list verification commands, link relevant issues, and include screenshots for UI changes. Call out database migrations, permission changes, and platform-specific behavior.

## Release & Configuration Notes

Never commit secrets or local SDK paths. For releases, increment `version` in `pubspec.yaml`, update `Guia_de_Uso_Cronos.pdf` for user-facing changes, verify tests, and tag `vX.Y.Z`. Keep Android minification disabled unless the WorkManager/Room keep rules are addressed.
