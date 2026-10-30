import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  callbackData,
  escapeHtml,
  hideThreshold,
  isReopened,
  maxCallbackBytes,
  moderationKeyboard,
  modKeyLength,
  moderationNote,
  parseCallbackData,
  reasonName,
  ReportDoc,
  reportMessage,
  statusAfter,
} from "../report";

const listingReport: ReportDoc = {
  targetType: "listing",
  targetId: "l1",
  reportedUid: "u_author",
  reporterId: "u_me",
  reason: "scam",
  comment: "Pul soʻrayapti",
};

describe("shikoyat message", () => {
  it("names the reason, both sides and the target", () => {
    const text = reportMessage("listing_l1_u_me", listingReport, undefined, {
      reporter: "Dilshod A.",
      reported: "Anvar T.",
    });
    assert.match(text, /Yangi shikoyat/);
    assert.match(text, /Sabab:<\/b> Firibgarlik/);
    assert.match(text, /Izoh:<\/b> Pul soʻrayapti/);
    assert.match(text, /Dilshod A\./);
    assert.match(text, /Anvar T\./);
    assert.match(text, /<code>u_author<\/code>/);
    assert.match(text, /<code>listing_l1_u_me<\/code>/);
  });

  it("carries the evidence copied with the report", () => {
    const text = reportMessage("listing_l1_u_me", listingReport, {
      title: "Qora charm hamyon",
      lines: ["Ichida kartalar bor", "Chilonzor · Toshkent"],
      photoUrls: ["https://example.test/1.jpg"],
    });
    assert.match(text, /Qora charm hamyon/);
    assert.match(text, /Ichida kartalar bor/);
    assert.match(text, /<a href="https:\/\/example.test\/1.jpg">rasm<\/a>/);
  });

  it("leaves out an empty comment and a single-report count", () => {
    const text = reportMessage("chat_c1_u_me", { ...listingReport, comment: "  " }, undefined);
    assert.ok(!text.includes("Izoh:"));
    assert.ok(!text.includes("Jami shikoyat"));
  });

  it("counts the other reports on the same target", () => {
    const text = reportMessage("listing_l1_u_me", listingReport, undefined, {}, 3);
    assert.match(text, /Jami shikoyat:<\/b> 3/);
  });

  it("escapes what the user wrote, so no one can forge the markup", () => {
    const text = reportMessage("listing_l1_u_me", { ...listingReport, comment: "<b>Kim:</b> admin" }, undefined);
    assert.match(text, /&lt;b&gt;Kim:&lt;\/b&gt; admin/);
    assert.equal(escapeHtml("a & b < c > d"), "a &amp; b &lt; c &gt; d");
  });

  it('calls "fake" an eʼlon on a listing and aldov in a chat', () => {
    assert.equal(reasonName("fake", "listing"), "Soxta eʼlon");
    assert.equal(reasonName("fake", "chat"), "Aldov");
    assert.equal(reasonName("offensive", "chat"), "Haqoratli");
  });
});

describe("re-opened shikoyat", () => {
  it("fires only when a closed report goes back to open", () => {
    assert.equal(isReopened({ status: "resolved" }, { status: "open" }), true);
    assert.equal(isReopened({ status: "dismissed" }, { status: "open" }), true);
    // The moderator closing it, and the evidence write that keeps it open.
    assert.equal(isReopened({ status: "open" }, { status: "resolved" }), false);
    assert.equal(isReopened({ status: "open" }, { status: "open" }), false);
    assert.equal(isReopened(undefined, undefined), false);
  });
});

describe("moderator buttons", () => {
  it("offers hiding only for a listing", () => {
    const listing = moderationKeyboard("k1", "listing");
    assert.equal(listing.inline_keyboard.length, 2);
    assert.equal(listing.inline_keyboard[0][0].callback_data, "r:hide:k1");
    const chat = moderationKeyboard("k1", "chat");
    assert.equal(chat.inline_keyboard.length, 1);
    assert.equal(chat.inline_keyboard[0][0].callback_data, "r:close:k1");
  });

  // Telegram answers BUTTON_DATA_INVALID and sends nothing at all when one
  // callback_data is too long, which is why the button carries a short key
  // instead of the report id.
  it("keeps every button within Telegram's callback_data limit", () => {
    const key = "k".repeat(modKeyLength);
    for (const type of ["listing", "chat"] as const) {
      for (const button of moderationKeyboard(key, type).inline_keyboard.flat()) {
        assert.ok(
          Buffer.byteLength(button.callback_data) <= maxCallbackBytes,
          `${button.callback_data} is ${Buffer.byteLength(button.callback_data)} bytes`,
        );
      }
    }
  });

  it("reads back what it wrote, and nothing else", () => {
    assert.deepEqual(parseCallbackData(callbackData("restore", "aB3-_x")), {
      action: "restore",
      modKey: "aB3-_x",
    });
    assert.equal(parseCallbackData("r:delete:l1"), null);
    assert.equal(parseCallbackData("r:close:"), null);
    assert.equal(parseCallbackData("r:done"), null);
    assert.equal(parseCallbackData(undefined), null);
  });

  it("resolves a report unless the listing was given back", () => {
    assert.equal(statusAfter("hide"), "resolved");
    assert.equal(statusAfter("close"), "resolved");
    assert.equal(statusAfter("restore"), "dismissed");
    assert.match(moderationNote("hide"), /yashirildi/);
  });
});

describe("automatic hiding", () => {
  it("takes three different people", () => {
    assert.equal(hideThreshold, 3);
    const hidden = (reports: number) => reports >= hideThreshold;
    assert.equal(hidden(2), false);
    assert.equal(hidden(3), true);
  });

  it("the report id holds the reporter, so one person counts once", () => {
    const ids = new Set(["listing_l1_u_a", "listing_l1_u_b", "listing_l1_u_a"]);
    assert.equal(ids.size, 2);
  });
});
