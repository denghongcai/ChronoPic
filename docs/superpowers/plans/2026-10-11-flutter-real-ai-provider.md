# Flutter Real AI Provider Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Port the Electron real AI enrichment stack (OpenAI-compatible streaming client, photo/memory prompts, enrichment orchestration, UI actions) to the Flutter release line so AI enrichment works without the Electron app.

**Architecture:** Add a real `OpenAiCompatibleAiClient` to `chronopic_ai` behind the existing `ChronoPicAiClient` interface, backed by `openai_dart` streaming chat completions. Port the JSON/label normalization helpers and both prompts verbatim from `packages/services-ai-pipeline`. Add enrichment orchestration (processing/completed/failed state machine, non-destructive to manual fields) to `chronopic_app`, and expose Generate/Apply actions in `chronopic_ui`.

**Tech Stack:** Flutter 3.47.7 stable / Dart 3.13.5 (toolchain upgraded mid-phase at user request; was 3.41.9/3.11.5), `openai_dart ^10.0.1` (latest stable, published 2026-10-04; temporarily pinned to ^8.1.0 on the old toolchain, restored after the upgrade — verified per the Step 235 dependency version rule), existing `chronopic_domain` models (`AiSettings`, `SemanticState`, `Memory` with generated fields, `AiPipelineStatus`).

---

## Context For The Implementing Engineer

You are working in `/home/dhc/workspace/ChronoPic`. The Flutter workspace is
`chronopic_flutter/` (Dart packages under `chronopic_flutter/packages/`, app in
`chronopic_flutter/apps/chronopic`). Run all `dart`/`flutter` commands from
`chronopic_flutter/` unless told otherwise.

**The Electron reference implementation lives in:**
- `packages/services-ai-pipeline/src/index.ts` — prompts + `VercelCompatibleAIClient`
- `packages/services-ai-pipeline/src/internal.ts` — `normalizeLabels`, `normalizeText`, `extractJsonObject`
- `packages/application/src/index.ts` — `enrichPhotoSemantic`, `enrichMemorySemantic`, `enrichPendingSemantics`

Read those files before coding. The prompts are copied **verbatim** (translated
mechanically to Dart string building). Do not "improve" prompt wording —
behavior parity with the Electron reference is the contract.

**Critical known quirk (from Electron Step 59):** the user's local
llama.cpp-compatible endpoint (`http://192.168.1.39:8888/v1`) returns
**SSE-formatted responses even for non-streaming requests**. Therefore:
always use the **streaming** API (`createStream` / `textDeltas`), never the
non-streaming `create` call. This is non-negotiable and must be covered by a
test.

**openai_dart 10.x API shape (verified against pub.dev README for 10.0.1):**

```dart
final client = OpenAIClient(
  config: OpenAIConfig(
    authProvider: ApiKeyProvider(apiKey),
    baseUrl: baseUrl, // e.g. 'http://192.168.1.39:8888/v1'
  ),
);

final stream = client.chat.completions.createStream(
  ChatCompletionCreateRequest(
    model: modelId,
    messages: [
      ChatMessage.user([
        ContentPart.text(promptText),
        ContentPart.imageUrl('data:image/jpeg;base64,$b64'), // data URLs accepted
      ]),
    ],
  ),
);

final text = await stream.collectText(); // or await for (final d in stream.textDeltas())
```

If the exact class names differ in the resolved 10.0.1 API docs, trust the
installed package's real signatures over this plan and adapt — but keep the
behavioral contract (streaming, data-URL image, strict-JSON extraction).

**Existing Dart facts you will build on (already verified):**
- `chronopic_ai/lib/src/ai_client.dart`: `ChronoPicAiClient` interface with
  `isEnabled` + `analyzePhoto({photoId, bytes, mime})`; `DisabledAiClient`,
  `FixtureSuccessAiClient`, `FixtureFailureAiClient`; `PhotoAiResult`
  (status/generatedLabels/generatedCaption/summary/provider/model/error).
- `chronopic_domain`: `AiSettings{apiKey, baseURL, model, providerName}`;
  `SemanticState` has `generatedCaption/summary/generatedLabels/aiStatus/...`;
  `Memory` has `generatedName/generatedDescription/generatedLabels/aiStatus/...`;
  `AiPipelineStatus` enum. Domain models have **no copyWith** — follow the
  repository's existing field-by-field record reconstruction pattern.
- `chronopic_app/lib/src/app_service.dart`: `scanDesktopDirectory`/`scanMediaSource`
  take a `ChronoPicAiClient` (UI currently passes nothing → `DisabledAiClient`);
  `updateAiSettings(AiSettings)` persists settings; `retryFailedAiQueue()` exists;
  per-status AI counts exist (added in Flutter Phase 5.5 / Step 146 — find the
  exact method name with grep before reusing).
- `chronopic_app/lib/src/indexer_service.dart:180-210`: scan-time
  `aiClient.analyzePhoto(...)` call site — extend the arguments here when the
  interface grows.
- `chronopic_database/lib/src/repository.dart`: mutates records by rebuilding
  them field-by-field (see `retryFailedAiQueue` around line 661). Add enrichment
  update methods in the same style. `updateMemory`, `setMemoryCover`,
  `listPhotosByMemory`-style memory listing exists (Phase 5.5).
- UI: photo detail inspector lives in
  `chronopic_flutter/packages/chronopic_ui/lib/src/detail/`; memory surfaces in
  `lib/src/memories/memory_pages.dart`. All interactive test hooks use stable
  `ValueKey<String>` keys — follow that convention.

**Verification baseline commands** (all from `chronopic_flutter/`):

```bash
flutter analyze
dart test packages/chronopic_ai/test packages/chronopic_app/test
dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_media/test
flutter test packages/chronopic_ui/test apps/chronopic/test
```

---

### Task 1: Port normalization helpers to `chronopic_ai`

**Files:**
- Create: `chronopic_flutter/packages/chronopic_ai/lib/src/normalize.dart`
- Create: `chronopic_flutter/packages/chronopic_ai/test/normalize_test.dart`
- Modify: `chronopic_flutter/packages/chronopic_ai/lib/chronopic_ai.dart` (export)

**Step 1: Write the failing test** — port the cases from
`tests/services-ai-pipeline.test.ts`. Cover at minimum:
- `extractJsonObject` parses a bare JSON object.
- It strips `<think>...</think>` reasoning blocks before parsing.
- It extracts from a fenced ```json block.
- It extracts the last balanced-looking JSON object from mixed text.
- It returns `null` for non-JSON text.
- `normalizeLabels` trims, drops empties/non-strings, de-duplicates, caps at 12.
- `normalizeText` trims and maps empty to `null`, non-string to `null`.

```dart
// test/normalize_test.dart (shape)
import 'package:chronopic_ai/src/normalize.dart';
import 'package:test/test.dart';

void main() {
  group('extractJsonObject', () {
    test('parses bare object', () {
      expect(extractJsonObject('{"a":1}'), {'a': 1});
    });
    test('strips think tags', () {
      expect(extractJsonObject('<think>hmm</think>{"a":1}'), {'a': 1});
    });
    test('parses fenced json', () {
      expect(extractJsonObject('```json\n{"a":1}\n```'), {'a': 1});
    });
    test('returns null for non-json', () {
      expect(extractJsonObject('no json here'), isNull);
    });
  });
  group('normalizeLabels', () {
    test('trims, dedupes, caps at 12', () {
      final labels = normalizeLabels([' a ', 'a', '', 3, 'b']);
      expect(labels, ['a', 'b']);
    });
  });
  group('normalizeText', () {
    test('maps empty and non-string to null', () {
      expect(normalizeText('  x  '), 'x');
      expect(normalizeText('   '), isNull);
      expect(normalizeText(42), isNull);
    });
  });
}
```

**Step 2: Run to verify it fails**

Run: `dart test packages/chronopic_ai/test/normalize_test.dart`
Expected: FAIL — `normalize.dart` / functions do not exist.

**Step 3: Implement** — mechanical Dart port of `internal.ts`:

```dart
// lib/src/normalize.dart
/// Normalization helpers ported from the Electron reference
/// (packages/services-ai-pipeline/src/internal.ts). Keep behavior identical.

final RegExp _thinkBlock = RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false);
final RegExp _fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false);

List<String> normalizeLabels(Object? labels) {
  if (labels is! List) return const <String>[];
  final seen = <String>{};
  for (final value in labels) {
    if (seen.length >= 12) break;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) seen.add(trimmed);
    }
  }
  return seen.toList(growable: false);
}

String? normalizeText(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, Object?>? extractJsonObject(String input) {
  final trimmed = input.replaceAll(_thinkBlock, '').trim();
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    final parsed = _tryParse(trimmed);
    if (parsed != null) return parsed;
  }
  final fenced = _fenced.firstMatch(trimmed);
  if (fenced != null) {
    final parsed = _tryParse(fenced.group(1)!);
    if (parsed != null) return parsed;
  }
  final candidates = RegExp(r'\{[\s\S]*?\}').allMatches(trimmed).toList();
  for (final match in candidates.reversed) {
    final parsed = _tryParse(match.group(0)!);
    if (parsed != null) return parsed;
  }
  return null;
}

Map<String, Object?>? _tryParse(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, Object?>) return decoded;
    if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
  } on FormatException {
    // fall through
  }
  return null;
}
```

(Add `import 'dart:convert';` at the top. Note: the TS version caps labels at
12 via `.slice(0, 12)` after de-dup; the Dart loop above is equivalent.)

Export from `lib/chronopic_ai.dart`:
`export 'src/normalize.dart';`

**Step 4: Run to verify it passes**

Run: `dart test packages/chronopic_ai/test/normalize_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add chronopic_flutter/packages/chronopic_ai
git commit -m "Port AI output normalization helpers to Flutter"
```

---

### Task 2: Add `openai_dart` and the real photo client

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ai/pubspec.yaml`
- Modify: `chronopic_flutter/packages/chronopic_ai/lib/src/ai_client.dart` (extend interface + result input type)
- Create: `chronopic_flutter/packages/chronopic_ai/lib/src/openai_compatible_ai_client.dart`
- Create: `chronopic_flutter/packages/chronopic_ai/test/openai_compatible_ai_client_test.dart`
- Modify: `chronopic_flutter/packages/chronopic_app/lib/src/indexer_service.dart` (pass richer args at the analyzePhoto call site)

**Step 1: Record the dependency version** (project rule from Step 235 — check
the latest stable from the official source and record it):
`openai_dart 8.1.0` — latest stable resolvable with Dart 3.11.5 (10.0.x needs Dart >=3.12).
Add it:

```bash
cd chronopic_flutter/packages/chronopic_ai && flutter pub add openai_dart:^8.1.0
```
> Implemented as `^8.1.0`, not 10.0.1: 10.0.x requires Dart >=3.12, toolchain ships 3.11.5 (deviation recorded in the step log).

**Step 2: Write the failing test** for `OpenAiCompatibleAiClient.analyzePhoto`
using a **local fake SSE server** (real streaming end-to-end, no mocks of the
parsing path):

```dart
// test/openai_compatible_ai_client_test.dart (shape)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chronopic_ai/chronopic_ai.dart';
import 'package:test/test.dart';

Future<HttpServer> _startFakeServer({
  required String bodyJson,
  required void Function(String rawBody) onRequest,
  bool sseEvenForNonStream = true, // the known endpoint quirk
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    onRequest(await utf8.decodeStream(req));
    req.response.headers.contentType = sseEvenForNonStream
        ? ContentType('text', 'event-stream')
        : ContentType.json;
    final payload = sseEvenForNonStream
        ? 'data: {"choices":[{"delta":{"content":${jsonEncode(bodyJson)}}}]}\n\n'
          'data: [DONE]\n\n'
        : jsonEncode({'choices': [{'message': {'content': bodyJson}}]});
    req.response.write(payload);
    await req.response.close();
  });
  return server;
}

void main() {
  test('analyzePhoto streams, sends data-URL image, parses strict JSON', () async {
    String? capturedBody;
    final server = await _startFakeServer(
      bodyJson: '{"caption":"City night","summary":"A city street at night.","labels":["city","night"]}',
      onRequest: (b) => capturedBody = b,
    );
    final client = OpenAiCompatibleAiClient(
      providerName: 'test-provider',
      model: 'test-model',
      apiKey: 'sk-test',
      baseUrl: 'http://localhost:${server.port}/v1',
    );
    final result = await client.analyzePhoto(
      photoId: 'p1',
      bytes: Uint8List.fromList([1, 2, 3]),
      mime: 'image/png',
    );
    await server.close(force: true);

    expect(result.status, AiPipelineStatus.completed);
    expect(result.generatedCaption, 'City night');
    expect(result.generatedLabels, ['city', 'night']);
    expect(result.provider, 'test-provider');
    expect(result.model, 'test-model');
    expect(capturedBody!, contains('"stream":true'));
    expect(capturedBody!, contains('data:image/png;base64,'));
    expect(capturedBody!, contains('"Output language for caption, summary, and labels: English (en-US)"'));
  });

  test('non-JSON model output surfaces an error result', () async {
    // server returns 'not json at all'
    // expect status == AiPipelineStatus.failed and error contains 'non-JSON'
  });

  test('zh-CN output locale is threaded into the prompt', () async {
    // context: const PhotoAiContext(outputLocale: 'zh-CN')
    // captured body contains 'Simplified Chinese (zh-CN)'
  });
}
```

**Step 3: Run to verify it fails**

Run: `dart test packages/chronopic_ai/test/openai_compatible_ai_client_test.dart`
Expected: FAIL — `OpenAiCompatibleAiClient` does not exist.

**Step 4: Implement.**

Extend the interface (keep the existing positional contract; add optional
metadata so the ported prompt can include datetime/gps/path like Electron):

```dart
abstract interface class ChronoPicAiClient {
  bool get isEnabled;
  Future<PhotoAiResult> analyzePhoto({
    required String photoId,
    required List<int> bytes,
    required String mime,
    DateTime? datetime,
    double? lat,
    double? lng,
    String? path,
  });
  Future<MemoryAiResult> analyzeMemory({
    required Memory memory,
    required List<PhotoRecord> photos,
    MemoryAIContext context = const MemoryAIContext(),
  });
}
```

Add `MemoryAiResult` and `MemoryAIContext` next to `PhotoAiResult` following
the same shape as Electron's `MemoryAIAnalysis`/`MemoryAIContext` (status +
generatedName/generatedDescription/generatedLabels/provider/model/error;
context holds `name`, `description`, `outputLocale`). Update the two fixture
clients to implement the new members (fixtures return canned/failing memory
results; ignore the new photo args).

Then the real client (port prompts verbatim — translate the TS template arrays
from `packages/services-ai-pipeline/src/index.ts:84-106` and `:139-176`
mechanically, including `describeOutputLocale`, working-draft vs generate
branching, and the max-word/count rules):

```dart
// lib/src/openai_compatible_ai_client.dart (shape)
final class OpenAiCompatibleAiClient implements ChronoPicAiClient {
  OpenAiCompatibleAiClient({
    required String providerName,
    required String model,
    required String apiKey,
    required String baseUrl,
  })  : _providerName = providerName,
        _modelId = model,
        _client = OpenAIClient(
          config: OpenAIConfig(
            authProvider: ApiKeyProvider(apiKey),
            baseUrl: baseUrl,
          ),
        );

  final String _providerName;
  final String _modelId;
  final OpenAIClient _client;

  @override
  bool get isEnabled => true;

  @override
  Future<PhotoAiResult> analyzePhoto({/* ... */}) async {
    final dataUrl =
        'data:${mime == 'image/jpeg' ? 'image/jpeg' : mime};base64,${base64Encode(bytes)}';
    // NOTE: streaming only — this endpoint family returns SSE even for
    // non-streaming requests (see Electron Step 59).
    final stream = _client.chat.completions.createStream(
      ChatCompletionCreateRequest(
        model: _modelId,
        messages: [
          ChatMessage.user([
            ContentPart.text(buildPhotoAnalysisPrompt(...)),
            ContentPart.imageUrl(dataUrl),
          ]),
        ],
      ),
    );
    final text = await stream.collectText();
    final payload = extractJsonObject(text);
    if (payload == null) {
      return PhotoAiResult(
        status: AiPipelineStatus.failed,
        error: 'Model returned non-JSON semantic output',
        provider: _providerName,
        model: _modelId,
      );
    }
    return PhotoAiResult(
      status: AiPipelineStatus.completed,
      generatedLabels: normalizeLabels(payload['labels']),
      generatedCaption: normalizeText(payload['caption']),
      summary: normalizeText(payload['summary']),
      provider: _providerName,
      model: _modelId,
    );
  }

  @override
  Future<MemoryAiResult> analyzeMemory({/* text-only stream, same pattern */}) async { ... }
}
```

Decide at implementation time whether non-JSON output **throws** (Electron
client behavior) or returns a `failed` result; the app-service orchestration
(Task 4) catches exceptions and marks `failed`, so returning `failed` from the
client is acceptable and simpler — pick one and test it. Update the fixture
clients for the new interface members. Update the
`indexer_service.dart:180-210` call site to pass the asset's `datetime`,
`lat`/`lng`, and `path` from `asset.metadata`/`asset.path` (keep behavior
otherwise identical).

**Step 5: Run to verify it passes**

Run: `dart test packages/chronopic_ai/test`
Expected: PASS (normalize + client + existing ai_client tests)

**Step 6: Commit**

```bash
git add chronopic_flutter/packages/chronopic_ai chronopic_flutter/packages/chronopic_app
git commit -m "Add OpenAI-compatible streaming AI client to Flutter"
```

---

### Task 3: Settings → client construction

**Files:**
- Create: `chronopic_flutter/packages/chronopic_ai/lib/src/ai_client_factory.dart`
- Test: `chronopic_flutter/packages/chronopic_ai/test/ai_client_factory_test.dart`
- Modify: `chronopic_flutter/packages/chronopic_ai/lib/chronopic_ai.dart` (export)

**Step 1: Write the failing test** —
`createAiClient(AiSettings)` returns `DisabledAiClient` when `isEnabled`
settings are incomplete (any of apiKey/baseURL/model empty) and returns an
`OpenAiCompatibleAiClient` (check `isEnabled == true`, provider/model fields)
when all four fields are present. Use `AiSettings` from domain.

**Step 2: Run to verify it fails.**

**Step 3: Implement** — a small factory:

```dart
ChronoPicAiClient createAiClient(AiSettings settings) {
  if (settings.apiKey.isEmpty || settings.baseURL.isEmpty || settings.model.isEmpty) {
    return const DisabledAiClient();
  }
  return OpenAiCompatibleAiClient(
    providerName: settings.providerName.isEmpty ? 'openai-compatible' : settings.providerName,
    model: settings.model,
    apiKey: settings.apiKey,
    baseUrl: settings.baseURL,
  );
}
```

**Step 4: Run to verify it passes; commit**

```bash
git add chronopic_flutter/packages/chronopic_ai
git commit -m "Add AI client factory from persisted settings"
```

---

### Task 4: Repository enrichment updates (chronopic_database)

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_database/lib/src/repository.dart`
- Test: `chronopic_flutter/packages/chronopic_database/test/repository_test.dart` (add group)

**Step 1: Write the failing tests:**
- `updatePhotoSemanticEnrichment(photoId, ...)` sets `aiStatus`, `aiError`,
  generated fields, provider/model/processedAt **without touching manual
  `caption`/`labels`**; unknown id is a no-op or throws (match existing
  repository conventions — check `getPhoto` handling first).
- `updateMemorySemanticEnrichment(memoryId, ...)` same for memory generated
  fields, leaving user `name`/`description` untouched.
- A per-status count method for the queue (if the existing per-status
  aggregation from Step 146 already covers this, skip and note it).

**Step 2: Run red. Step 3: Implement** in the repository's existing
field-by-field rebuild style (see `retryFailedAiQueue` ~line 661 for the
pattern). **Step 4: green; commit**

```bash
git add chronopic_flutter/packages/chronopic_database
git commit -m "Add semantic enrichment update methods to repository"
```

---

### Task 5: App-service enrichment orchestration (chronopic_app)

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_app/lib/src/app_service.dart`
- Test: `chronopic_flutter/packages/chronopic_app/test/ai_enrichment_test.dart` (new file)

Port from `packages/application/src/index.ts` (`enrichPhotoSemantic` :99,
`enrichMemorySemantic` :229, `enrichPendingSemantics` :135). State machine for
both photo and memory:

1. Guard: built-in client not enabled → throw `AI enrichment is not configured`.
2. Set status `processing`, clear error.
3. Analyze (memory path: sample up to 24 photos of the memory, datetime desc;
   no photos → `failed` with `Memory has no photos to analyze`).
4. On success: write generated fields + `completed`.
5. On any error: write `failed` + error message + processedAt. Manual fields
   are never written.

Batch: `enrichPendingSemantics({int limit = 12, PhotoAIContext? context})`
processes photos whose status is `pending`, `failed`, **or `disabled`**
(Electron Step 63 behavior — configured-late libraries must be enrichable
without re-index). Return counts `{processed, completed, failed}`.

Locale threading: resolve `outputLocale` from persisted settings the same way
the UI language settings work (Flutter has interface + AI output language
settings since Step 170 — grep `LocaleSetting`/`aiOutputLocale` in
`chronopic_domain` and reuse; map to `'zh-CN'`/`'en-US'` strings for the
prompt).

Client selection: scan paths (`scanDesktopDirectory`/`scanMediaSource`) and
enrichment methods default to `createAiClient(createBackup().settings.ai)`
instead of a hard `DisabledAiClient` default; keep the parameter for tests to
inject fixtures.

**Tests (red → green):** use `FixtureSuccessAiClient` /
`FixtureFailureAiClient` against a repository seeded from the parity backup
fixture (see existing `app_service_test.dart` for the seeding pattern):
- photo enrichment success writes generated fields, preserves manual caption/tags;
- failure marks `failed` with error text, preserves manual fields;
- memory with zero photos → `failed` with the exact message;
- memory enrichment success writes generatedName/Description/Labels, preserves name/description;
- `MemoryAIContext` drafts are forwarded to `analyzeMemory` (assert on a recording fake client);
- batch processes pending+failed+disabled only, and reports accurate counts.

**Commit:** `git commit -m "Add AI enrichment orchestration to Flutter app service"`

---

### Task 6: UI surfaces (chronopic_ui)

**Files:**
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/detail/` (photo inspector AI block)
- Modify: `chronopic_flutter/packages/chronopic_ui/lib/src/memories/memory_pages.dart` (memory AI suggestions)
- Test: `chronopic_flutter/packages/chronopic_ui/test/ai_surfaces_test.dart` (new)

Follow the Electron product rules (Steps 62, 63, 90):
- generated content is stored in generated fields and displayed distinctly;
  it never overwrites user-authored title/description/caption.
- photo inspector: show AI status, generated caption/summary/labels, and a
  `Generate AI Metadata` action — stable key `generate-photo-ai-button`.
  Errors surface via the existing inspector status feedback.
- memory page: an explicit AI suggestions entry (per Step 90, keep it behind a
  compact action, not default page content) that opens a dialog/panel showing
  status + suggested title/description/labels with `Use suggestion` actions
  that only fill local drafts. Keys: `memory-ai-suggest-button`,
  `use-ai-title-button`, `use-ai-description-button`.
- Notifications: next to the existing retry control add `Enrich Pending`
  (key `enrich-pending-button`) calling `enrichPendingSemantics`.

**Widget tests (red → green):** seed the shell with a repository/fixture
client as existing tests do; assert the actions exist, trigger them, and
assert visible generated content / suggestion application. Use
`FixtureSuccessAiClient` so no network is involved.

**Commit:** `git commit -m "Expose AI enrichment actions in Flutter UI"`

---

### Task 7: Full verification gate + docs closeout

**Step 1: Full local gate** (from `chronopic_flutter/` unless noted):

```bash
flutter analyze
dart test packages/chronopic_ai/test packages/chronopic_app/test
dart test packages/chronopic_domain/test packages/chronopic_database/test packages/chronopic_media/test
flutter test packages/chronopic_ui/test apps/chronopic/test
cd apps/chronopic && flutter build linux --debug && flutter build apk --debug
```

Also from repo root: `git diff --check`.

**Step 2 (optional but recommended): live endpoint smoke.** With the user's
local endpoint reachable, run a tiny Dart script (or a temporary test marked
skip-by-default) that constructs `OpenAiCompatibleAiClient` against
`http://192.168.1.39:8888/v1` / model `unsloth/gemma-4-E4B-it-GGUF` and runs
one real `analyzePhoto`. Record the result in the step log. If the endpoint is
unreachable from this machine, record it as skipped with the reason.

**Step 3: Update durable docs:**
- `PLAN.md` — remove/promote Active Direction item 1 (AI/map config validation
  remains; note real AI provider landed).
- `AGENTS.md` — update `Current State` (latest step, AI provider landed).
- Append the execution step entry to
  `docs/superpowers/plans/agent-step-log-flutter-line.md` (per AGENTS.md Working Rules).
- `docs/flutter-refactor-phases.md` — add Phase 15 entry with verification evidence.

**Step 4: Commit** `git commit -m "Execute Flutter real AI provider phase"`

---

## Non-Goals

- Memory-candidate **generation** (clustering) — separate phase; only
  candidate naming could ride along if trivial.
- Real map rendering (AMap) — separate phase.
- Embedding/vector output (`embeddingRef` stays `null`, matching Electron).
- New AI providers (Anthropic etc.) — the OpenAI-compatible surface covers the
  existing settings contract.
