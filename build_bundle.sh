#!/usr/bin/env bash
# Compila el App Bundle (AAB) release de Cronos para Google Play Store.
# Uso: ./build_bundle.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "==> flutter pub get"
flutter pub get

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

echo "==> flutter build appbundle --release"
flutter build appbundle --release

AAB=build/app/outputs/bundle/release/app-release.aab
echo ""
echo "App Bundle listo para Google Play: $AAB"
