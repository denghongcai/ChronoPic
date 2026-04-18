import assert from "node:assert/strict";
import test from "node:test";

import { DEFAULT_FILTER } from "@chronopic/domain";

test("DEFAULT_FILTER keeps stable paging and sort defaults", () => {
  assert.deepEqual(DEFAULT_FILTER, {
    limit: 60,
    offset: 0,
    sortBy: "datetime",
    sortDirection: "desc"
  });
});
