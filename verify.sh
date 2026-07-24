#!/usr/bin/env bash
# Corre analyze + tests y guarda TODO en verify_output.txt para que Claude
# lo lea directamente de la carpeta y corrija en loop.
cd "$(dirname "$0")"
{
  echo "===== $(date) ====="
  echo "== flutter --version =="
  flutter --version
  echo
  echo "== flutter pub get =="
  flutter pub get
  echo
  echo "== flutter analyze =="
  flutter analyze
  echo "ANALYZE_EXIT=$?"
  echo
  echo "== flutter test =="
  flutter test -r expanded
  echo "TEST_EXIT=$?"
} > verify_output.txt 2>&1
echo "Listo. Resultados en verify_output.txt — dile a Claude que lo revise."
tail -5 verify_output.txt
