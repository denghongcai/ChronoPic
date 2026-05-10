#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
APP_DIR="$ROOT_DIR/chronopic_flutter/apps/chronopic"
VERSION="${CHRONOPIC_RELEASE_VERSION:-$(node -p "JSON.parse(require('fs').readFileSync('package.json', 'utf8')).version")}"
DIST_DIR="${FLUTTER_RELEASE_DIST_DIR:-$ROOT_DIR/dist/flutter-release/linux}"
BUNDLE_DIR="$APP_DIR/build/linux/x64/release/bundle"
ARCHIVE_NAME="chronopic-flutter-linux-x64-$VERSION.tar.gz"
ARCHIVE_TARGET="$DIST_DIR/$ARCHIVE_NAME"

log() {
  printf '[flutter-release][linux] %s\n' "$*"
}

log "Flutter version"
flutter --version

cd "$APP_DIR"

if [[ "${CHRONOPIC_FLUTTER_CLEAN:-0}" == "1" ]]; then
  log "running flutter clean"
  flutter clean
fi

log "building Linux release bundle"
flutter build linux --release

if [[ ! -x "$BUNDLE_DIR/chronopic" ]]; then
  echo "Missing Flutter Linux executable: $BUNDLE_DIR/chronopic" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
tar -C "$BUNDLE_DIR" -czf "$ARCHIVE_TARGET" .

(
  cd "$DIST_DIR"
  sha256sum "$ARCHIVE_NAME" > "$ARCHIVE_NAME.sha256"
)

log "wrote $ARCHIVE_TARGET"
log "wrote $ARCHIVE_TARGET.sha256"
