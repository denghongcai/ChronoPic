import assert from "node:assert/strict";
import test from "node:test";

import { DEFAULT_FILTER, discoveryQueryToPhotoFilter, photoFilterToDiscoveryQuery } from "@chronopic/domain";

test("DEFAULT_FILTER keeps stable paging and sort defaults", () => {
  assert.deepEqual(DEFAULT_FILTER, {
    limit: 60,
    offset: 0,
    sortBy: "datetime",
    sortDirection: "desc"
  });
});

test("discovery query helpers map search text and shared filter fields consistently", () => {
  const discovery = {
    text: "misty forest",
    memoryId: "memory-1",
    favorite: true,
    hasGps: true,
    sortBy: "updatedAt" as const,
    sortDirection: "asc" as const,
  };

  const filter = discoveryQueryToPhotoFilter(discovery);
  assert.deepEqual(filter, {
    query: "misty forest",
    favorite: true,
    memoryId: "memory-1",
    hasGps: true,
    sortBy: "updatedAt",
    sortDirection: "asc",
  });

  assert.deepEqual(photoFilterToDiscoveryQuery(filter), discovery);
});
