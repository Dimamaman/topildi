import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { botLang, checkContact, cleanName, normalizePhone, parseUpdate, reply, sessionState } from "../telegram";

const msg = (m: object) => ({ message: { chat: { id: 7 }, from: { id: 42, first_name: "Malika" }, ...m } });

describe("bot updates", () => {
  it("/start with a session id", () => {
    assert.deepEqual(parseUpdate(msg({ text: "/start AbCdEfGhIjKlMnOp_-12" })), {
      kind: "start",
      chatId: 7,
      sid: "AbCdEfGhIjKlMnOp_-12",
      lang: "uz",
    });
  });

  it("the sign-in link pasted into the chat", () => {
    assert.deepEqual(parseUpdate(msg({ text: "https://t.me/menikitopildi_bot?start=AbCdEfGhIjKlMnOp_-12" })), {
      kind: "start",
      chatId: 7,
      sid: "AbCdEfGhIjKlMnOp_-12",
      lang: "uz",
    });
  });

  it("/start without (or with a malformed) payload is not a sign-in", () => {
    assert.equal(parseUpdate(msg({ text: "/start" }))?.kind, "other");
    assert.equal(parseUpdate(msg({ text: "/start a.b" }))?.kind, "other");
  });

  it("a shared contact", () => {
    const m = parseUpdate(msg({ contact: { phone_number: "998901234567", user_id: 42 } }));
    assert.deepEqual(m, {
      kind: "contact",
      chatId: 7,
      fromId: 42,
      contactUserId: 42,
      phone: "998901234567",
      name: "Malika",
      lang: "uz",
    });
  });

  it("ignores updates without a message", () => {
    assert.equal(parseUpdate({}), null);
  });

  it("answers Russian speakers in Russian", () => {
    assert.equal(botLang("ru-RU"), "ru");
    assert.equal(botLang("en"), "uz");
    assert.equal(botLang(undefined), "uz");
  });
});

describe("names", () => {
  it("keeps a plain name", () => {
    assert.equal(cleanName("  Malika  "), "Malika");
  });

  it("collapses spaces and drops invisible characters", () => {
    assert.equal(cleanName("Dima\u200b \n  Aka"), "Dima Aka");
  });

  it("keeps emoji whole", () => {
    assert.equal(cleanName("Dima 🔥"), "Dima 🔥");
    assert.equal(cleanName("👨\u200d👩\u200d👧"), "👨\u200d👩\u200d👧");
  });

  it("cuts to 30 characters without splitting an emoji", () => {
    assert.equal(Array.from(cleanName("a".repeat(29) + "🔥🔥")).length, 30);
    assert.equal(cleanName("a".repeat(29) + "🔥🔥"), "a".repeat(29) + "🔥");
  });

  it("falls back when nothing printable is left", () => {
    assert.equal(cleanName("\u200b\u200e "), "Foydalanuvchi");
  });
});

describe("contacts", () => {
  it("normalizes Uzbek numbers", () => {
    assert.equal(normalizePhone("998901234567"), "+998901234567");
    assert.equal(normalizePhone("+998 90 123-45-67"), "+998901234567");
    assert.equal(normalizePhone("+79161234567"), null);
    assert.equal(normalizePhone("99890123"), null);
  });

  it("accepts only the sender's own contact", () => {
    assert.deepEqual(checkContact({ fromId: 42, contactUserId: 42, phone: "998901234567" }), {
      ok: true,
      phone: "+998901234567",
    });
    assert.deepEqual(checkContact({ fromId: 42, contactUserId: 43, phone: "998901234567" }), {
      ok: false,
      reason: "foreign",
    });
    // Typed-in contacts carry no user_id.
    assert.deepEqual(checkContact({ fromId: 42, phone: "998901234567" }), { ok: false, reason: "foreign" });
  });

  it("refuses non-Uzbek numbers", () => {
    assert.deepEqual(checkContact({ fromId: 42, contactUserId: 42, phone: "79161234567" }), {
      ok: false,
      reason: "badPhone",
    });
  });
});

describe("sessions", () => {
  const now = 1_000_000;

  it("pending until the contact arrives, verified after", () => {
    assert.equal(sessionState({ status: "pending", expiresAt: now + 1 }, now), "pending");
    assert.equal(sessionState({ status: "verified", phone: "+998901234567", expiresAt: now + 1 }, now), "verified");
  });

  it("expires", () => {
    assert.equal(sessionState({ status: "verified", phone: "+998901234567", expiresAt: now }, now), "expired");
  });

  it("missing", () => {
    assert.equal(sessionState(undefined, now), "missing");
    assert.equal(sessionState({ status: "pending" }, now), "missing");
  });
});

describe("replies", () => {
  it("asks for the contact with a share button", () => {
    const r = reply(7, "uz", "askContact", true);
    assert.equal(r.method, "sendMessage");
    assert.deepEqual(r.reply_markup, {
      keyboard: [[{ text: "📱 Raqamni ulashish", request_contact: true }]],
      resize_keyboard: true,
      one_time_keyboard: true,
    });
  });

  it("removes the keyboard otherwise", () => {
    assert.deepEqual(reply(7, "ru", "verified").reply_markup, { remove_keyboard: true });
  });
});
