import assert from "node:assert/strict";
import test from "node:test";

import {
  assertCompleteDictionaries,
  createTranslator,
  formatCount,
  normalizeAIOutputLocale,
  normalizeLocale,
  resolveAIOutputLocale,
} from "@chronopic/i18n";

test("i18n dictionaries contain every required key", () => {
  assert.doesNotThrow(() => assertCompleteDictionaries());
});

test("createTranslator falls back and interpolates values", () => {
  const t = createTranslator("zh-CN");

  assert.equal(t("sidebar.memories"), "记忆");
  assert.equal(t("memory.detail.photos", { count: 3 }), "3 张照片");
});

test("locale normalization and AI output locale resolution are stable", () => {
  assert.equal(normalizeLocale("zh-Hans-CN"), "zh-CN");
  assert.equal(normalizeLocale("fr-FR"), "en-US");
  assert.equal(normalizeAIOutputLocale("zh-CN"), "zh-CN");
  assert.equal(normalizeAIOutputLocale("bad"), "follow-ui");
  assert.equal(resolveAIOutputLocale({ locale: "zh-CN", aiOutputLocale: "follow-ui" }), "zh-CN");
  assert.equal(resolveAIOutputLocale({ locale: "zh-CN", aiOutputLocale: "en-US" }), "en-US");
});

test("formatCount uses the target locale", () => {
  assert.equal(formatCount("en-US", 1200), "1,200");
});
