#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
APP_DIR="$ROOT_DIR/chronopic_flutter/apps/chronopic"
DIST_DIR="${FLUTTER_RELEASE_DIST_DIR:-$ROOT_DIR/dist/flutter-release/android}"
APK_SOURCE="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
AAB_SOURCE="$APP_DIR/build/app/outputs/bundle/release/app-release.aab"
APK_TARGET="$DIST_DIR/chronopic-flutter-android-release.apk"
AAB_TARGET="$DIST_DIR/chronopic-flutter-android-release.aab"

log() {
  printf '[flutter-release][android] %s\n' "$*"
}

log "Flutter version"
flutter --version

log "Android toolchain"
flutter doctor -v | sed -n '/Android toolchain/,+8p'

cd "$APP_DIR"

if [[ "${CHRONOPIC_FLUTTER_CLEAN:-0}" == "1" ]]; then
  log "running flutter clean"
  flutter clean
fi

log "building release APK"
flutter build apk --release

log "building release app bundle"
flutter build appbundle --release

mkdir -p "$DIST_DIR"
cp "$APK_SOURCE" "$APK_TARGET"
cp "$AAB_SOURCE" "$AAB_TARGET"

(
  cd "$DIST_DIR"
  sha256sum "$(basename "$APK_TARGET")" > "$(basename "$APK_TARGET").sha256"
  sha256sum "$(basename "$AAB_TARGET")" > "$(basename "$AAB_TARGET").sha256"
)

log "wrote $APK_TARGET"
log "wrote $AAB_TARGET"
log "wrote sha256 files under $DIST_DIR"
