#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
APP_DIR="$ROOT_DIR/chronopic_flutter/apps/chronopic"
DEVICE_ID="${ANDROID_DEVICE_ID:-emulator-5554}"
PACKAGE_NAME="com.example.chronopic"
RUN_ID="${MOBILE_E2E_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
OUT_DIR="${MOBILE_E2E_OUT_DIR:-$ROOT_DIR/.tmp/mobile-e2e/android/$RUN_ID}"
ASSERT_SCRIPT="$SCRIPT_DIR/assert_android_deep_e2e_artifacts.mjs"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RUN_STATUS="running"

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR/summary.json"

log() {
  printf '[mobile-e2e][%s][%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$DEVICE_ID" "$*"
}

artifact_label() {
  local artifact_path="$1"
  printf '%s' "${artifact_path#$OUT_DIR/}"
}

require_artifact() {
  local artifact_path="$1"
  if [[ ! -s "$artifact_path" ]]; then
    log "missing required artifact: $(artifact_label "$artifact_path")"
    return 1
  fi
}

write_summary() {
  local status="$1"
  node - "$OUT_DIR/summary.json" "$DEVICE_ID" "$PACKAGE_NAME" "$STARTED_AT" "$status" "$OUT_DIR" <<'NODE'
const fs = require('fs');
const path = require('path');

const [, , summaryPath, deviceId, packageName, startedAt, status, outDir] = process.argv;
const scenarios = [
  {
    name: 'first-run-baseline',
    artifacts: ['01-first-run.png', '01-first-run.xml'],
  },
  {
    name: 'permission-denied-recovery',
    artifacts: ['02-denied.png', '02-denied.xml'],
  },
  {
    name: 'full-photo-library-access',
    artifacts: ['03-full-access.png', '03-full-access.xml'],
  },
  {
    name: 'limited-selected-photo-access',
    artifacts: ['04-limited-access.png', '04-limited-access.xml', '04-permissions.txt'],
  },
  {
    name: 'restart-persistence',
    artifacts: ['05-restart.png', '05-restart.xml'],
  },
  {
    name: 'metadata-backup-restore',
    artifacts: ['06-restore.png', '06-restore.xml', 'backup.json'],
  },
];

const summary = {
  status,
  startedAt,
  finishedAt: new Date().toISOString(),
  deviceId,
  packageName,
  outDir: path.resolve(outDir),
  scenarios: scenarios.map((scenario) => ({
    ...scenario,
    artifactPaths: scenario.artifacts.map((artifact) => path.join(path.resolve(outDir), artifact)),
  })),
};

fs.writeFileSync(summaryPath, `${JSON.stringify(summary, null, 2)}\n`);
NODE
}

finish() {
  local exit_code=$?
  if [[ "$RUN_STATUS" == "running" ]]; then
    RUN_STATUS="failed"
    write_summary "$RUN_STATUS" || true
    log "runner failed with exit code $exit_code"
  fi
}

trap finish EXIT

run_scenario() {
  local scenario_name="$1"
  shift
  log "scenario start: $scenario_name"
  "$@"
  log "scenario end: $scenario_name"
}

dump_xml() {
  local target="$1"
  local label
  label="$(artifact_label "$target")"
  for attempt in 1 2 3; do
    log "uiautomator dump attempt $attempt for $label"
    adb -s "$DEVICE_ID" shell input keyevent 224 >/dev/null 2>&1 || true
    adb -s "$DEVICE_ID" shell wm dismiss-keyguard >/dev/null 2>&1 || true
    adb -s "$DEVICE_ID" shell pkill -f uiautomator >/dev/null 2>&1 || true
    adb -s "$DEVICE_ID" shell rm -f /sdcard/window.xml >/dev/null 2>&1 || true
    timeout 12 adb -s "$DEVICE_ID" shell uiautomator dump /sdcard/window.xml >/dev/null 2>&1 || true
    if adb -s "$DEVICE_ID" shell cat /sdcard/window.xml > "$target" 2>/dev/null &&
      grep -F "<hierarchy" "$target" >/dev/null; then
      require_artifact "$target"
      log "captured XML artifact: $label"
      return 0
    fi
    sleep 1
  done
  log "failed to dump UI XML to $label"
  return 1
}

dump_ui() {
  local name="$1"
  dump_xml "$OUT_DIR/$name.xml"
  timeout 20 adb -s "$DEVICE_ID" exec-out screencap -p > "$OUT_DIR/$name.png"
  require_artifact "$OUT_DIR/$name.png"
  log "captured screenshot artifact: $name.png"
}

assert_ui_contains() {
  local name="$1"
  local expected="$2"
  grep -F "$expected" "$OUT_DIR/$name.xml" >/dev/null
}

tap() {
  adb -s "$DEVICE_ID" shell input tap "$1" "$2"
}

tap_ui_value() {
  local name="$1"
  local value="$2"
  local coords
  coords="$(
    node - "$OUT_DIR/$name.xml" "$value" <<'NODE'
const fs = require('fs');
const [, , filePath, needle] = process.argv;
const xml = fs.readFileSync(filePath, 'utf8');
const nodes = xml.match(/<node\b[^>]*>/g) ?? [];

for (const node of nodes) {
  const text = /text="([^"]*)"/.exec(node)?.[1] ?? '';
  const desc = /content-desc="([^"]*)"/.exec(node)?.[1] ?? '';
  if (text !== needle && desc !== needle) continue;
  const bounds = /bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"/.exec(node);
  if (!bounds) continue;
  const [, x1, y1, x2, y2] = bounds.map(Number);
  console.log(`${Math.floor((x1 + x2) / 2)} ${Math.floor((y1 + y2) / 2)}`);
  process.exit(0);
}

console.error(`UI value not found: ${needle}`);
process.exit(1);
NODE
  )"
  tap $coords
}

dismiss_system_anr_if_present() {
  local name="$1"
  if grep -F "isn't responding" "$OUT_DIR/$name.xml" >/dev/null; then
    tap 540 1340
  fi
}

wait_for_ui_contains() {
  local name="$1"
  local expected="$2"
  for attempt in $(seq 1 30); do
    log "wait attempt $attempt for '$expected' in $name"
    if ! dump_ui "$name"; then
      sleep 2
      continue
    fi
    if assert_ui_contains "$name" "$expected"; then
      return 0
    fi
    dismiss_system_anr_if_present "$name"
    sleep 2
  done
  echo "Timed out waiting for $expected in $name" >&2
  return 1
}

reset_media_permissions() {
  log "resetting Android media permissions"
  for permission in \
    android.permission.READ_MEDIA_IMAGES \
    android.permission.READ_MEDIA_VIDEO \
    android.permission.READ_MEDIA_VISUAL_USER_SELECTED; do
    adb -s "$DEVICE_ID" shell pm revoke "$PACKAGE_NAME" "$permission" >/dev/null 2>&1 || true
    adb -s "$DEVICE_ID" shell pm clear-permission-flags "$PACKAGE_NAME" "$permission" user-set user-fixed >/dev/null 2>&1 || true
  done
}

reset_app_state() {
  log "clearing app state"
  adb -s "$DEVICE_ID" shell am force-stop "$PACKAGE_NAME" || true
  adb -s "$DEVICE_ID" shell pm clear "$PACKAGE_NAME"
  reset_media_permissions
}

launch_app() {
  log "launching $PACKAGE_NAME"
  adb -s "$DEVICE_ID" shell am start -n "$PACKAGE_NAME/.MainActivity"
  sleep 8
  adb -s "$DEVICE_ID" shell input keyevent 224 >/dev/null 2>&1 || true
  adb -s "$DEVICE_ID" shell wm dismiss-keyguard >/dev/null 2>&1 || true
}

wait_for_external_storage() {
  for attempt in $(seq 1 30); do
    if adb -s "$DEVICE_ID" shell "mkdir -p /sdcard/Pictures && test -d /sdcard/Pictures" >/dev/null 2>&1; then
      return 0
    fi
    log "waiting for external storage attempt $attempt"
    sleep 2
  done
  log "external storage did not become ready"
  return 1
}

clean_media_fixture_dirs() {
  wait_for_external_storage
  for attempt in 1 2 3 4 5; do
    if adb -s "$DEVICE_ID" shell rm -rf /sdcard/Pictures/ChronoPicDeepE2E /sdcard/Pictures/ChronoPicSmoke; then
      return 0
    fi
    log "retrying media fixture cleanup attempt $attempt"
    sleep 2
  done
  log "failed to clean media fixture directories"
  return 1
}

prepare_media_fixtures() {
  log "preparing Android media fixtures"
  clean_media_fixture_dirs
  adb -s "$DEVICE_ID" shell mkdir -p /sdcard/Pictures/ChronoPicDeepE2E
  adb -s "$DEVICE_ID" push android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png /sdcard/Pictures/ChronoPicDeepE2E/deep-1.png
  adb -s "$DEVICE_ID" push android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png /sdcard/Pictures/ChronoPicDeepE2E/deep-2.png
  adb -s "$DEVICE_ID" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/ChronoPicDeepE2E/deep-1.png
  adb -s "$DEVICE_ID" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/ChronoPicDeepE2E/deep-2.png
}

open_photo_permission_dialog() {
  local first_run_name="$1"
  wait_for_ui_contains "$first_run_name" "Choose Photos"
  tap_ui_value "$first_run_name" "Choose Photos"
  wait_for_ui_contains "$first_run_name-permission" "Allow chronopic to access photos and videos on this device?"
}

open_limited_photo_picker() {
  for attempt in 1 2 3 4 5; do
    log "limited access tap attempt $attempt"
    tap_ui_value "04-first-run-permission" "ALLOW LIMITED ACCESS"
    sleep 3
    if ! dump_ui "04-limited-picker"; then
      continue
    fi
    if assert_ui_contains "04-limited-picker" "Select photos and videos you allow this app to access"; then
      return 0
    fi
  done
  echo "Timed out opening limited photo picker" >&2
  return 1
}

run_denied_permission() {
  log "checking denied permission recovery"
  reset_app_state
  launch_app
  open_photo_permission_dialog "02-first-run"
  tap_ui_value "02-first-run-permission" "DON’T ALLOW"
  wait_for_ui_contains "02-denied" "Photo library permission denied. Open settings to grant access."
}

run_full_access() {
  log "checking full photo-library access"
  reset_app_state
  launch_app
  open_photo_permission_dialog "03-first-run"
  tap_ui_value "03-first-run-permission" "ALLOW ALL"
  wait_for_ui_contains "03-full-access" "Photo library scan complete: 2 imported, 0 updated, 0 skipped, 0 errors, 0 missing"
}

run_limited_access() {
  log "checking limited selected-photo access"
  reset_app_state
  launch_app
  open_photo_permission_dialog "04-first-run"
  open_limited_photo_picker
  tap 177 827
  sleep 1
  tap 540 827
  sleep 1
  dump_ui "04-limited-selected"
  tap_ui_value "04-limited-selected" "Allow (2)"
  wait_for_ui_contains "04-limited-access" "Limited photo access: 2 imported, 0 updated, 0 skipped, 0 errors, 0 missing"
  adb -s "$DEVICE_ID" shell dumpsys package "$PACKAGE_NAME" > "$OUT_DIR/04-permissions.txt"
  grep -F "android.permission.READ_MEDIA_VISUAL_USER_SELECTED: granted=true" "$OUT_DIR/04-permissions.txt"
  grep -F "android.permission.READ_MEDIA_IMAGES: granted=false" "$OUT_DIR/04-permissions.txt"
}

run_restart_and_backup_restore() {
  log "checking restart persistence"
  adb -s "$DEVICE_ID" shell am force-stop "$PACKAGE_NAME"
  launch_app
  wait_for_ui_contains "05-restart" "Select"

  log "checking metadata backup restore"
  adb -s "$DEVICE_ID" shell run-as "$PACKAGE_NAME" cat /data/user/0/$PACKAGE_NAME/code_cache/.local/share/chronopic_flutter/chronopic-backup.json > "$OUT_DIR/backup.json"
  node -e "const fs=require('fs'); const data=JSON.parse(fs.readFileSync(process.argv[1], 'utf8')); if (data.photos.length !== 2) process.exit(1);" "$OUT_DIR/backup.json"
  adb -s "$DEVICE_ID" shell pm clear "$PACKAGE_NAME"
  adb -s "$DEVICE_ID" push "$OUT_DIR/backup.json" /data/local/tmp/chronopic-backup.json
  adb -s "$DEVICE_ID" shell chmod 644 /data/local/tmp/chronopic-backup.json
  adb -s "$DEVICE_ID" shell run-as "$PACKAGE_NAME" mkdir -p /data/user/0/$PACKAGE_NAME/code_cache/.local/share/chronopic_flutter
  adb -s "$DEVICE_ID" shell run-as "$PACKAGE_NAME" cp /data/local/tmp/chronopic-backup.json /data/user/0/$PACKAGE_NAME/code_cache/.local/share/chronopic_flutter/chronopic-backup.json
  launch_app
  wait_for_ui_contains "06-restore" "Select"
  assert_ui_contains "06-restore" "2 items"
}

adb -s "$DEVICE_ID" wait-for-device
adb -s "$DEVICE_ID" shell getprop sys.boot_completed | grep -q 1

cd "$APP_DIR"
log "output directory: $OUT_DIR"
log "building debug APK"
flutter build apk --debug
log "installing debug APK"
timeout 240 adb -s "$DEVICE_ID" install -r -t --no-streaming build/app/outputs/flutter-apk/app-debug.apk

prepare_media_fixtures

run_first_run_baseline() {
  log "capturing first-run baseline"
  reset_app_state
  launch_app
  wait_for_ui_contains "01-first-run" "Choose Photos"
}

run_scenario "first-run-baseline" run_first_run_baseline
run_scenario "permission-denied-recovery" run_denied_permission
run_scenario "full-photo-library-access" run_full_access
run_scenario "limited-selected-photo-access" run_limited_access
run_scenario "restart-and-backup-restore" run_restart_and_backup_restore

node "$ASSERT_SCRIPT" "$OUT_DIR"
RUN_STATUS="passed"
write_summary "$RUN_STATUS"

log "Android deep E2E runner prepared $OUT_DIR"
