#!/usr/bin/env bash
# Compila el APK release de Cronos listo para instalar en el teléfono.
# Uso: ./build_apk.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

echo "==> flutter build apk --release"
flutter build apk --release

APK=build/app/outputs/flutter-apk/app-release.apk
echo ""
echo "APK listo: $APK"
echo "Instálalo con el teléfono conectado por USB:"
echo "  flutter install --release"
echo "o cópialo al teléfono y ábrelo (permitir 'orígenes desconocidos')."
