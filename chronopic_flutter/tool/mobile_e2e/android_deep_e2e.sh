#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
APP_DIR="$ROOT_DIR/chronopic_flutter/apps/chronopic"
DEVICE_ID="${ANDROID_DEVICE_ID:-emulator-5554}"
PACKAGE_NAME="com.example.chronopic"
OUT_DIR="${MOBILE_E2E_OUT_DIR:-$ROOT_DIR/.tmp/mobile-e2e/android}"

mkdir -p "$OUT_DIR"

log() {
  echo "[mobile-e2e] $*"
}

dump_xml() {
  local target="$1"
  for _ in $(seq 1 2); do
    adb -s "$DEVICE_ID" shell input keyevent 224 >/dev/null 2>&1 || true
    adb -s "$DEVICE_ID" shell wm dismiss-keyguard >/dev/null 2>&1 || true
    adb -s "$DEVICE_ID" shell pkill -f uiautomator >/dev/null 2>&1 || true
    adb -s "$DEVICE_ID" shell rm -f /sdcard/window.xml >/dev/null 2>&1 || true
    timeout 12 adb -s "$DEVICE_ID" shell uiautomator dump /sdcard/window.xml >/dev/null 2>&1 || true
    if adb -s "$DEVICE_ID" shell cat /sdcard/window.xml > "$target" 2>/dev/null &&
      grep -F "<hierarchy" "$target" >/dev/null; then
      return 0
    fi
    sleep 1
  done
  echo "Failed to dump UI XML to $target" >&2
  return 1
}

dump_ui() {
  local name="$1"
  dump_xml "$OUT_DIR/$name.xml"
  timeout 20 adb -s "$DEVICE_ID" exec-out screencap -p > "$OUT_DIR/$name.png"
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
  for _ in $(seq 1 30); do
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
  for permission in \
    android.permission.READ_MEDIA_IMAGES \
    android.permission.READ_MEDIA_VIDEO \
    android.permission.READ_MEDIA_VISUAL_USER_SELECTED; do
    adb -s "$DEVICE_ID" shell pm revoke "$PACKAGE_NAME" "$permission" >/dev/null 2>&1 || true
    adb -s "$DEVICE_ID" shell pm clear-permission-flags "$PACKAGE_NAME" "$permission" user-set user-fixed >/dev/null 2>&1 || true
  done
}

reset_app_state() {
  adb -s "$DEVICE_ID" shell am force-stop "$PACKAGE_NAME" || true
  adb -s "$DEVICE_ID" shell pm clear "$PACKAGE_NAME"
  reset_media_permissions
}

launch_app() {
  adb -s "$DEVICE_ID" shell am start -n "$PACKAGE_NAME/.MainActivity"
  sleep 8
  adb -s "$DEVICE_ID" shell input keyevent 224 >/dev/null 2>&1 || true
  adb -s "$DEVICE_ID" shell wm dismiss-keyguard >/dev/null 2>&1 || true
}

prepare_media_fixtures() {
  adb -s "$DEVICE_ID" shell rm -rf /sdcard/Pictures/ChronoPicDeepE2E /sdcard/Pictures/ChronoPicSmoke
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
  tap_ui_value "04-first-run-permission" "ALLOW LIMITED ACCESS"
  wait_for_ui_contains "04-limited-picker" "Select photos and videos you allow this app to access"
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
log "building debug APK"
flutter build apk --debug
log "installing debug APK"
timeout 240 adb -s "$DEVICE_ID" install -r -t --no-streaming build/app/outputs/flutter-apk/app-debug.apk

log "preparing media fixtures"
prepare_media_fixtures

log "capturing first-run baseline"
reset_app_state
launch_app
wait_for_ui_contains "01-first-run" "Choose Photos"

run_denied_permission
run_full_access
run_limited_access
run_restart_and_backup_restore

echo "Android deep E2E runner prepared $OUT_DIR"
