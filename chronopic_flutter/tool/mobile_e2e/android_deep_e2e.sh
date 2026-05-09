#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
APP_DIR="$ROOT_DIR/chronopic_flutter/apps/chronopic"
DEVICE_ID="${ANDROID_DEVICE_ID:-emulator-5554}"
PACKAGE_NAME="com.example.chronopic"
OUT_DIR="${MOBILE_E2E_OUT_DIR:-$ROOT_DIR/.tmp/mobile-e2e/android}"

mkdir -p "$OUT_DIR"

dump_window_xml() {
  local target="$1"
  adb -s "$DEVICE_ID" shell uiautomator dump /sdcard/window.xml >/dev/null
  adb -s "$DEVICE_ID" shell cat /sdcard/window.xml > "$target"
}

wait_for_first_run_ui() {
  local target="$OUT_DIR/01-first-run.xml"
  for _ in $(seq 1 20); do
    dump_window_xml "$target"
    if grep -F "Choose Photos" "$target" >/dev/null; then
      return 0
    fi
    if grep -F "isn't responding" "$target" >/dev/null; then
      adb -s "$DEVICE_ID" shell input tap 540 1340
    fi
    sleep 2
  done
  echo "Timed out waiting for ChronoPic first-run UI" >&2
  return 1
}

adb -s "$DEVICE_ID" wait-for-device
adb -s "$DEVICE_ID" shell getprop sys.boot_completed | grep -q 1

cd "$APP_DIR"
flutter build apk --debug
timeout 240 adb -s "$DEVICE_ID" install -r -t --no-streaming build/app/outputs/flutter-apk/app-debug.apk

adb -s "$DEVICE_ID" shell am force-stop "$PACKAGE_NAME" || true
adb -s "$DEVICE_ID" shell pm clear "$PACKAGE_NAME"

adb -s "$DEVICE_ID" shell mkdir -p /sdcard/Pictures/ChronoPicDeepE2E
adb -s "$DEVICE_ID" push android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png /sdcard/Pictures/ChronoPicDeepE2E/deep-1.png
adb -s "$DEVICE_ID" push android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png /sdcard/Pictures/ChronoPicDeepE2E/deep-2.png
adb -s "$DEVICE_ID" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/ChronoPicDeepE2E/deep-1.png
adb -s "$DEVICE_ID" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/ChronoPicDeepE2E/deep-2.png

adb -s "$DEVICE_ID" shell am start -n "$PACKAGE_NAME/.MainActivity"
sleep 8

wait_for_first_run_ui
adb -s "$DEVICE_ID" exec-out screencap -p > "$OUT_DIR/01-first-run.png"

echo "Android deep E2E runner prepared $OUT_DIR"
