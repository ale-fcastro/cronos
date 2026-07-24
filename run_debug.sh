#!/usr/bin/env bash
# Limpia el build (por si quedó cacheado sin la lib nativa de sqlite3 recién
# agregada) y corre la app, guardando TODOS los logs en run_log.txt.
cd "$(dirname "$0")"
flutter clean
flutter pub get
flutter run "$@" 2>&1 | tee run_log.txt
