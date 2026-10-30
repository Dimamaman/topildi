import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { storagePrefixes } from "../account";

describe("account deletion", () => {
  it("empties the user's folders and those of their listings and claims", () => {
    assert.deepEqual(storagePrefixes("u1", ["l1"], ["l9_u1_1"]), [
      "topildi/uploads/u1/",
      "topildi/users/u1/",
      "topildi/listings/l1/",
      "topildi/claims/l9_u1_1/",
    ]);
  });

  it("every prefix ends with a slash, so u1 never matches u10", () => {
    for (const p of storagePrefixes("u1", ["l1"], ["c1"])) assert.ok(p.endsWith("/"));
  });
});
