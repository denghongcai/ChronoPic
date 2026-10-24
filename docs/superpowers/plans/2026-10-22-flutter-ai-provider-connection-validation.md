# Phase 17: Flutter AI Provider Connection Validation

## Goal

Let users verify the OpenAI-compatible endpoint, API key, and configured model
from the Settings form before saving them or starting photo enrichment.

The check is metadata-only: request `GET {baseURL}/models` with bearer
authentication, confirm the configured model id is listed, and do not upload
photos or call a generation endpoint. A successful check confirms access to the
provider's model catalog; it does not guarantee that a later inference request
will succeed.

## Current Grounding

- The Flutter release line already has a real streaming OpenAI-compatible client
  and AI enrichment orchestration.
- Settings currently classifies AI configuration by field presence and saves
  credentials, but has no connection check.
- The Flutter AI client interface only exposes photo and memory analysis.
- Flutter's Map browse surface is still a fixed error/placeholder canvas. Its
  saved AMap settings are not consumed by a Flutter map renderer, so Map browse
  completion is a separate product phase rather than part of this credential
  check.

## User Flow

1. The user enters provider, base URL, model, and API key in Settings.
2. `Test Connection` checks the current form values without saving them.
3. The UI shows a localized, secret-safe result and a clear recovery hint.
4. The user saves the values separately when ready.
5. Editing any field clears the previous result so stale success is not shown.

## Result States

- `connected`: provider returned a valid model catalog containing the configured
  model id.
- `incompleteSettings`: one or more readiness fields are empty.
- `invalidBaseUrl`: URL is malformed, non-HTTP(S), or contains query/fragment
  data that would make the API root ambiguous.
- `unauthorized` / `forbidden`: provider rejected the supplied credentials or
  access.
- `modelNotListed`: endpoint responded, but the configured model id was absent.
- `endpointUnavailable`: provider returned not-found or another client error
  for the model-list request.
- `rateLimited`: provider returned HTTP 429.
- `providerError`: provider returned a server error.
- `invalidResponse`: response was not a JSON model list with model ids.
- `timedOut` / `networkError`: the request timed out or could not reach the
  endpoint.

Do not render raw exception text or provider response bodies. Do not include the
API key or full authorization header in logs or the result model. Use an 8
second request timeout and cap the response body at 1 MiB.

## Implementation Tasks

### 1. Add the AI Connection Check API

Create `chronopic_flutter/packages/chronopic_ai/lib/src/connection_check.dart`
and export it from `chronopic_flutter/packages/chronopic_ai/lib/chronopic_ai.dart`.

Define a typed status and result:

```dart
enum AiConnectionStatus {
  connected,
  incompleteSettings,
  invalidBaseUrl,
  unauthorized,
  forbidden,
  modelNotListed,
  endpointUnavailable,
  rateLimited,
  providerError,
  invalidResponse,
  timedOut,
  networkError,
}

final class AiConnectionCheckResult {
  const AiConnectionCheckResult({
    required this.status,
    required this.model,
    this.missingFields = const <String>[],
  });

  final AiConnectionStatus status;
  final String model;
  final List<String> missingFields;

  bool get connected => status == AiConnectionStatus.connected;
}
```

Implement `checkAiConnection(AiSettings settings, {Duration timeout = ...})`
with `dart:io HttpClient`. Reuse `getAiReadiness` for required fields, append
`/models` to the configured API root while preserving `/v1`, send
`Authorization: Bearer <apiKey>`, disable redirects, and compare the returned
`data[*].id` values with the trimmed configured model. Close the client in
`finally`; map HTTP/network/format failures to typed states without returning
raw response content.

### 2. Add App-Service Orchestration

Add `ChronoPicAppService.testAiConnection(AiSettings settings)` as a thin
forwarder to `checkAiConnection`.

The method must accept draft settings and must not update or persist repository
settings. Verify that behavior with an injected/local checker in
`chronopic_flutter/packages/chronopic_app/test/app_service_test.dart`.

### 3. Add the Settings Interaction

Update `SettingsPage` and `AiSettingsPanel` in
`chronopic_flutter/packages/chronopic_ui/lib/src/settings/settings_pages.dart`:

- add `Test Connection` next to `Save AI Settings`;
- build the request from the current text controllers;
- disable the action while the request is running;
- display a localized result for each typed status;
- clear the displayed result whenever any of the four fields changes;
- retain `obscureText` for the API key and never show it in result copy;
- explain that the check validates endpoint access and model listing without
  sending a photo or generating content.

Wire the action through `ChronoPicHome` to
`ChronoPicAppService.testAiConnection`. Keep Save independent: testing must not
save settings, and saving must not start a test request.

### 4. Add Regression Coverage

Create `chronopic_flutter/packages/chronopic_ai/test/connection_check_test.dart`
with a local `HttpServer` and cover:

- successful authorized request to `/v1/models` with exact model match;
- missing fields and malformed/non-HTTP URL without a request;
- 401, 403, 404, 429, and 5xx status mapping;
- configured model absent from the catalog;
- malformed/non-list JSON;
- timeout and unreachable endpoint;
- no photo bytes or generation request are sent.

Extend `chronopic_flutter/packages/chronopic_ui/test/ai_surfaces_test.dart` or
`chronopic_flutter/packages/chronopic_ui/test/chronopic_home_test.dart` to cover
the Settings button, in-flight state, success/failure copy, stale-result reset
after field edits, and separate Save behavior. Use a local test endpoint or an
injected checker; do not use real provider secrets.

### 5. Update Product and Phase Records

Update `README.md`, `PLAN.md`, `docs/flutter-refactor-phases.md`, and `AGENTS.md`:

- make Phase 17 the active phase and link this plan;
- describe Flutter Map browsing as unavailable until its placeholder is replaced;
- record the Map finding as a separate future feature: Flutter Map browse is a
  placeholder and saved AMap credentials are currently not consumed there;
- retain iOS live verification as blocked on macOS/Xcode;
- update the Phase 15 AI-provider exit note so it points to Phase 17.

Append execution details to
`docs/superpowers/plans/agent-step-log-flutter-2026-10-12.md` and update the
`Current State` section of `AGENTS.md` in place.

## Verification

Run the focused AI and Settings tests, then the Flutter package/UI checks:

```bash
cd chronopic_flutter
dart test packages/chronopic_ai/test/connection_check_test.dart packages/chronopic_ai/test/ai_client_factory_test.dart packages/chronopic_app/test/app_service_test.dart
flutter test packages/chronopic_ui/test/ai_surfaces_test.dart packages/chronopic_ui/test/chronopic_home_test.dart
dart analyze packages/chronopic_ai packages/chronopic_app packages/chronopic_ui apps/chronopic
flutter test packages/chronopic_ui/test apps/chronopic/test
flutter build linux --debug
flutter build apk --debug
cd ..
git diff --check
```

Follow `docs/agent-verification-script.md` for the changed scenes. The Electron
scenes are reference-only; for the active Flutter release line, cover Settings
configuration and restart persistence with Flutter widget/app-service tests,
builds, and a Linux debug launch. Do not claim a live real-provider check unless
the user has configured a reachable endpoint; fake local HTTP tests are the
automated transport evidence.

## Execution Status

Implementation and automated checks are complete locally. The phase remains
open for desktop first-frame verification:

- `dart test packages/chronopic_ai/test packages/chronopic_app/test
  packages/chronopic_media/test packages/chronopic_domain/test
  packages/chronopic_database/test` — 114 passed.
- `flutter test packages/chronopic_ui/test apps/chronopic/test` — 35 passed.
- `dart analyze packages/chronopic_ai packages/chronopic_app
  packages/chronopic_ui apps/chronopic` — no issues.
- `flutter build linux --debug` and `flutter build apk --debug` — built; the
  Android build emitted upcoming Gradle/AGP/Kotlin support warnings.
- Scene 7: a draft connection check does not persist; separately saved AI
  settings survive an app-service restart.
- Scene 8: widget tests cover successful and unauthorized results, in-flight
  disabled state, clearing stale results after edits, and saving separately.
- Scene 1: the Linux binary started and exposed a Dart VM service, but under
  Xvfb the window stayed at 10x10 off-screen/unmapped and the screenshot was
  black, including with software rendering. A real desktop-capable first-frame
  check remains necessary.
- Electron Playwright scenes were skipped because Electron is reference-only.
  A real-provider smoke check was skipped because no reachable user endpoint
  was configured; iOS live verification remains blocked on macOS/Xcode.
- `git diff --check` — clean after the record update.

## Exit Gate

- The user can test unsaved AI settings without sending photo data or generating
  content.
- Success means the configured model is visible through the provider's model
  catalog endpoint; the UI says this is not an inference guarantee.
- All failure statuses have localized, actionable, secret-safe copy.
- Editing draft fields clears stale results; testing and saving remain separate.
- Focused tests, Flutter analyze/UI tests, Linux and Android debug builds, and
  `git diff --check` pass.
- Verification scenes and skipped checks are recorded in the active step log.
- Scene 1 first-frame visual confirmation remains required before Phase 17 is
  marked complete.
