import assert from "node:assert/strict";
import test from "node:test";

import {
  clamp,
  dedupeStrings,
  formatMonthKey,
  parseStringArray,
  runWithConcurrency,
  serializeStringArray
} from "@chronopic/shared-utils";

test("string array helpers round-trip and ignore invalid JSON", () => {
  const serialized = serializeStringArray(["alpha", "beta"]);

  assert.deepEqual(parseStringArray(serialized), ["alpha", "beta"]);
  assert.deepEqual(parseStringArray("not-json"), []);
});

test("dedupeStrings removes blanks and duplicates", () => {
  assert.deepEqual(dedupeStrings(["one", " ", "two", "one", "two"]), ["one", "two"]);
});

test("formatMonthKey returns readable group label", () => {
  assert.equal(formatMonthKey(Date.UTC(2026, 3, 18)), "2026-04");
  assert.equal(formatMonthKey(null), "Unknown");
});

test("clamp bounds values", () => {
  assert.equal(clamp(9, 1, 6), 6);
  assert.equal(clamp(-2, 1, 6), 1);
  assert.equal(clamp(4, 1, 6), 4);
});

test("runWithConcurrency executes every item once", async () => {
  const output: number[] = [];

  await runWithConcurrency([1, 2, 3, 4], 2, async (value) => {
    output.push(value);
  });

  output.sort((left, right) => left - right);
  assert.deepEqual(output, [1, 2, 3, 4]);
});
