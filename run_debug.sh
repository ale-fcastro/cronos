#!/usr/bin/env bash
# Corre la app en el teléfono conectado y guarda TODOS los logs en run_log.txt
# para que Claude pueda leerlos y depurar.
cd "$(dirname "$0")"
flutter run 2>&1 | tee run_log.txt
