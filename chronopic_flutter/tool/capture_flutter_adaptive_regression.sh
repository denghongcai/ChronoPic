#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$FLUTTER_ROOT/.." && pwd)"
APP_DIR="$FLUTTER_ROOT/apps/chronopic"
APP_BIN="$APP_DIR/build/linux/x64/debug/bundle/chronopic"
BACKUP_FIXTURE="$REPO_ROOT/tests/fixtures/flutter-parity/chronopic-backup-v1.json"
OUTPUT_DIR="$REPO_ROOT/test-results/flutter-adaptive-regression"

WIDTHS=(1366 1600 2048)
SURFACES=(populated-grid detail)
HEIGHT=920

prepare_state() {
  local data_home
  data_home="$(mktemp -d)"
  mkdir -p "$data_home/chronopic_flutter"
  node - "$BACKUP_FIXTURE" "$data_home/chronopic_flutter/chronopic-backup.json" <<'NODE'
const fs = require('node:fs');

const input = process.argv[2];
const output = process.argv[3];
const backup = JSON.parse(fs.readFileSync(input, 'utf8'));
backup.settings.locale = {
  locale: 'en-US',
  aiOutputLocale: 'follow-ui',
};
fs.writeFileSync(output, `${JSON.stringify(backup, null, 2)}\n`);
NODE
  printf '%s' "$data_home"
}

capture_surface() {
  local width="$1"
  local surface="$2"
  local output="$OUTPUT_DIR/${width}-${surface}.png"
  local data_home
  data_home="$(prepare_state)"
  rm -f "$output"

  xvfb-run -a -s "-screen 0 ${width}x1200x24" bash -lc '
    set -euo pipefail
    cd "$1"
    export XDG_DATA_HOME="$2"
    export GDK_BACKEND=x11
    export LIBGL_ALWAYS_SOFTWARE=1
    export CHRONOPIC_CAPTURE_SURFACE="$3"
    export CHRONOPIC_WINDOW_WIDTH="$4"
    export CHRONOPIC_WINDOW_HEIGHT="$5"
    "$6" &
    app_pid=$!
    sleep 9
    scrot -a 0,0,"$4","$5" "$7"
    kill "$app_pid"
    wait "$app_pid" || true
  ' bash "$APP_DIR" "$data_home" "$surface" "$width" "$HEIGHT" "$APP_BIN" "$output"

  if [[ ! -s "$output" ]]; then
    echo "Missing or empty adaptive screenshot: $output" >&2
    exit 1
  fi
}

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*.png

echo "Building Flutter Linux debug bundle..."
(cd "$APP_DIR" && flutter build linux --debug)

for width in "${WIDTHS[@]}"; do
  for surface in "${SURFACES[@]}"; do
    echo "Capturing Flutter adaptive surface: ${width}-${surface}"
    capture_surface "$width" "$surface"
  done
done

echo "Captured Flutter adaptive screenshots in ${OUTPUT_DIR#$REPO_ROOT/}"
