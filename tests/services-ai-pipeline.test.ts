import assert from "node:assert/strict";
import test from "node:test";

import { extractJsonObject, normalizeLabels, normalizeText } from "@chronopic/services-ai-pipeline/internal";

test("extractJsonObject tolerates think blocks and fenced JSON", () => {
  const payload = extractJsonObject(`
<think>internal reasoning</think>
\`\`\`json
{"caption":"Golden sunset","summary":"Warm light over a quiet shoreline.","labels":["sunset","shore","golden"]}
\`\`\`
  `);

  assert.deepEqual(payload, {
    caption: "Golden sunset",
    summary: "Warm light over a quiet shoreline.",
    labels: ["sunset", "shore", "golden"],
  });
});

test("normalizeLabels dedupes, trims, and caps label count", () => {
  const labels = normalizeLabels([" sunset ", "shore", "", "shore", "golden", 1, "evening"]);
  assert.deepEqual(labels, ["sunset", "shore", "golden", "evening"]);
});

test("normalizeText trims strings and rejects non-strings", () => {
  assert.equal(normalizeText("  quiet scene  "), "quiet scene");
  assert.equal(normalizeText("   "), null);
  assert.equal(normalizeText(42), null);
});
