import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import { ChronoPicConfigStore } from "@chronopic/infra-config";

test("infra-config persists and normalizes AI settings", () => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "chronopic-config-"));
  const filePath = path.join(tempDir, "settings.json");
  const store = new ChronoPicConfigStore(filePath);

  assert.deepEqual(store.getAISettings(), {
    apiKey: "",
    baseURL: "",
    model: "",
    providerName: "openai-compatible",
  });

  const saved = store.saveAISettings({
    apiKey: "  sk-test  ",
    baseURL: "  http://localhost:8888/v1  ",
    model: "  local-model  ",
    providerName: "  openai-compatible  ",
  });

  assert.deepEqual(saved, {
    apiKey: "sk-test",
    baseURL: "http://localhost:8888/v1",
    model: "local-model",
    providerName: "openai-compatible",
  });

  const reloaded = new ChronoPicConfigStore(filePath);
  assert.deepEqual(reloaded.getAISettings(), saved);
});

test("infra-config persists and normalizes map settings", () => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "chronopic-config-"));
  const filePath = path.join(tempDir, "settings.json");
  const store = new ChronoPicConfigStore(filePath);

  assert.deepEqual(store.getMapSettings(), {
    apiKey: "",
    securityJsCode: "",
  });

  const saved = store.saveMapSettings({
    apiKey: "  amap-test-key  ",
    securityJsCode: "  security-code  ",
  });

  assert.deepEqual(saved, {
    apiKey: "amap-test-key",
    securityJsCode: "security-code",
  });

  const reloaded = new ChronoPicConfigStore(filePath);
  assert.deepEqual(reloaded.getMapSettings(), saved);
});
