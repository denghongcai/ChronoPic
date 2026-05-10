#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DEVICE_ID="${ANDROID_DEVICE_ID:-emulator-5554}"
PACKAGE_NAME="com.example.chronopic"
RUN_ID="${MOBILE_E2E_REPEAT_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
BASE_OUT_DIR="${MOBILE_E2E_REPEAT_OUT_DIR:-$ROOT_DIR/.tmp/mobile-e2e/android-repeat/$RUN_ID}"
RUNNER="$SCRIPT_DIR/android_deep_e2e.sh"
ASSERT_SCRIPT="$SCRIPT_DIR/assert_android_deep_e2e_artifacts.mjs"

mkdir -p "$BASE_OUT_DIR"

log() {
  printf '[mobile-e2e-repeat][%s][%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$DEVICE_ID" "$*"
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

clean_emulator_state() {
  log "cleaning emulator app/media state"
  adb -s "$DEVICE_ID" wait-for-device
  adb -s "$DEVICE_ID" shell am force-stop "$PACKAGE_NAME" >/dev/null 2>&1 || true
  adb -s "$DEVICE_ID" shell pm clear "$PACKAGE_NAME" >/dev/null 2>&1 || true
  clean_media_fixture_dirs
}

write_combined_summary() {
  node - "$BASE_OUT_DIR/combined-summary.json" "$DEVICE_ID" "$RUN_ID" "$BASE_OUT_DIR/run-1" "$BASE_OUT_DIR/run-2" <<'NODE'
const fs = require('fs');
const path = require('path');

const [, , summaryPath, deviceId, runId, runOneDir, runTwoDir] = process.argv;

function readRunSummary(runDir) {
  const summaryPath = path.join(runDir, 'summary.json');
  return JSON.parse(fs.readFileSync(summaryPath, 'utf8'));
}

const runOne = readRunSummary(runOneDir);
const runTwo = readRunSummary(runTwoDir);
const summary = {
  status: runOne.status === 'passed' && runTwo.status === 'passed' ? 'passed' : 'failed',
  runId,
  deviceId,
  finishedAt: new Date().toISOString(),
  runs: [
    {
      name: 'run-1',
      outDir: path.resolve(runOneDir),
      status: runOne.status,
      summaryPath: path.join(path.resolve(runOneDir), 'summary.json'),
    },
    {
      name: 'run-2',
      outDir: path.resolve(runTwoDir),
      status: runTwo.status,
      summaryPath: path.join(path.resolve(runTwoDir), 'summary.json'),
    },
  ],
};

fs.writeFileSync(summaryPath, `${JSON.stringify(summary, null, 2)}\n`);
NODE
}

for run_number in 1 2; do
  run_out_dir="$BASE_OUT_DIR/run-$run_number"
  mkdir -p "$run_out_dir"
  log "starting clean Android deep E2E run $run_number: $run_out_dir"
  clean_emulator_state
  ANDROID_DEVICE_ID="$DEVICE_ID" MOBILE_E2E_OUT_DIR="$run_out_dir" "$RUNNER"
  node "$ASSERT_SCRIPT" "$run_out_dir"
  log "completed clean Android deep E2E run $run_number"
done

write_combined_summary
log "Android deep E2E two-run summary: $BASE_OUT_DIR/combined-summary.json"
