import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { displayName, finderOf } from "../returns";

const chat = { finderId: "u2", names: { u1: "Sardor A.", u2: "Dinmuhammad D." } };

describe("who returned an item", () => {
  it("takes the finder from the chat that closed the listing", () => {
    const found = finderOf({ type: "lost", authorId: "u1", authorName: "Sardor A." }, chat);
    assert.deepEqual(found, { uid: "u2", name: "Dinmuhammad D." });
  });

  it("without a chat, a found listing was returned by its author", () => {
    assert.deepEqual(finderOf({ type: "found", authorId: "u1", authorName: "Sardor A." }, undefined), {
      uid: "u1",
      name: "Sardor A.",
    });
  });

  it("a lost listing closed without a chat names nobody", () => {
    assert.equal(finderOf({ type: "lost", authorId: "u1", authorName: "Sardor A." }, undefined), null);
  });
});

describe("the name on a returned listing", () => {
  it("is written only with consent", () => {
    const finder = { uid: "u2", name: "Dinmuhammad D." };
    assert.equal(displayName(finder, true), "Dinmuhammad D.");
    assert.equal(displayName(finder, false), null);
  });

  it("stays empty when there is no name to show", () => {
    assert.equal(displayName({ uid: "u2", name: "" }, true), null);
  });
});
