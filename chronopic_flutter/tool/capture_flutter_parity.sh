#!/usr/bin/env bash
set -euo pipefail

MODES=("${@:-all}")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$FLUTTER_ROOT/.." && pwd)"
APP_DIR="$FLUTTER_ROOT/apps/chronopic"
APP_BIN="$APP_DIR/build/linux/x64/debug/bundle/chronopic"
BACKUP_FIXTURE="$REPO_ROOT/tests/fixtures/flutter-parity/chronopic-backup-v1.json"
OUTPUT_DIR="$REPO_ROOT/test-results/flutter-electron-parity/flutter"

declare -A SCREENSHOTS=(
  ["empty-home"]="01-empty-home.png"
  ["populated-grid"]="02-populated-grid.png"
  ["map"]="03-map.png"
  ["timeline"]="04-timeline.png"
  ["detail"]="05-detail.png"
  ["gallery"]="06-gallery.png"
  ["favorites"]="07-favorites.png"
  ["memories-list"]="08-memories-list.png"
  ["memory-detail"]="09-memory-detail.png"
  ["settings"]="10-settings.png"
  ["notifications"]="11-notifications.png"
  ["zh-locale"]="12-zh-locale.png"
  ["restart-persistence"]="13-restart-persistence.png"
)

SURFACES=(
  "empty-home"
  "populated-grid"
  "map"
  "timeline"
  "detail"
  "gallery"
  "favorites"
  "memories-list"
  "memory-detail"
  "settings"
  "notifications"
  "zh-locale"
  "restart-persistence"
)

prepare_state() {
  local surface="$1"
  local data_home
  data_home="$(mktemp -d)"
  if [[ "$surface" != "empty-home" ]]; then
    mkdir -p "$data_home/chronopic_flutter"
    if [[ "$surface" == "zh-locale" || "$surface" == "restart-persistence" ]]; then
      cp "$BACKUP_FIXTURE" "$data_home/chronopic_flutter/chronopic-backup.json"
    else
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
    fi
  fi
  printf '%s' "$data_home"
}

capture_surface() {
  local surface="$1"
  local output="$OUTPUT_DIR/${SCREENSHOTS[$surface]}"
  local data_home
  data_home="$(prepare_state "$surface")"
  rm -f "$output"

  xvfb-run -a -s "-screen 0 1600x1200x24" bash -lc '
    set -euo pipefail
    cd "$1"
    export XDG_DATA_HOME="$2"
    export GDK_BACKEND=x11
    export LIBGL_ALWAYS_SOFTWARE=1
    export CHRONOPIC_CAPTURE_SURFACE="$3"
    "$4" &
    app_pid=$!
    sleep 9
    scrot -a 0,0,1440,920 "$5"
    kill "$app_pid"
    wait "$app_pid" || true
  ' bash "$APP_DIR" "$data_home" "$surface" "$APP_BIN" "$output"

  if [[ ! -s "$output" ]]; then
    echo "Missing or empty Flutter parity screenshot: $output" >&2
    exit 1
  fi
}

mkdir -p "$OUTPUT_DIR"

echo "Building Flutter Linux debug bundle..."
(cd "$APP_DIR" && flutter build linux --debug)

for mode in "${MODES[@]}"; do
  if [[ "$mode" == "all" ]]; then
    rm -f "$OUTPUT_DIR"/*.png
    for surface in "${SURFACES[@]}"; do
      echo "Capturing Flutter surface: $surface"
      capture_surface "$surface"
    done
  elif [[ -n "${SCREENSHOTS[$mode]:-}" ]]; then
    echo "Capturing Flutter surface: $mode"
    capture_surface "$mode"
  else
    echo "Unknown capture mode: $mode" >&2
    echo "Expected one of: all ${SURFACES[*]}" >&2
    exit 2
  fi
done

echo "Captured Flutter parity screenshots in ${OUTPUT_DIR#$REPO_ROOT/}"
