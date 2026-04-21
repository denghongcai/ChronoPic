import assert from "node:assert/strict";
import test from "node:test";

import { SCHEMA_SQL } from "@chronopic/infra-db/schema";

test("infra-db semantic schema includes generated AI fields and provider metadata columns", () => {
  assert.match(SCHEMA_SQL, /generated_labels TEXT NOT NULL DEFAULT '\[\]'/);
  assert.match(SCHEMA_SQL, /generated_caption TEXT/);
  assert.match(SCHEMA_SQL, /summary TEXT/);
  assert.match(SCHEMA_SQL, /ai_provider TEXT/);
  assert.match(SCHEMA_SQL, /ai_model TEXT/);
  assert.match(SCHEMA_SQL, /ai_processed_at INTEGER/);
  assert.match(SCHEMA_SQL, /ai_error TEXT/);
});

test("infra-db memory schema includes generated AI memory fields", () => {
  assert.match(SCHEMA_SQL, /generated_name TEXT/);
  assert.match(SCHEMA_SQL, /generated_description TEXT/);
  assert.match(SCHEMA_SQL, /generated_labels TEXT NOT NULL DEFAULT '\[\]'/);
  assert.match(SCHEMA_SQL, /CREATE TABLE IF NOT EXISTS memories/);
});
