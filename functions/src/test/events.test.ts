import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { claimCreated, claimUpdated, messageCreated, reminders } from "../events";
import { multicast } from "../payload";
import { langOf, pushText, shorten } from "../texts";

const listing = { title: "Qora hamyon", authorName: "Dilshod A." };
const claim = { listingId: "l1", listingAuthorId: "u1", claimantId: "u2", attempt: 1, status: "pending" };
const chat = {
  listingId: "l1",
  listingTitle: "Qora hamyon",
  members: ["u1", "u2"],
  finderId: "u1",
  names: { u1: "Dilshod A.", u2: "Malika K." },
};

describe("claims", () => {
  it("a new claim goes to the listing's author and opens its claims", () => {
    const d = claimCreated(claim, listing)!;
    assert.equal(d.to, "u1");
    assert.equal(d.route, "/listing/l1/claims");
    assert.deepEqual(d.record, { kind: "newClaim", listingId: "l1", listingTitle: "Qora hamyon" });
  });

  it("accepting opens the chat (the claim's id) for the claimant", () => {
    const d = claimUpdated("l1_u2_1", claim, { ...claim, status: "accepted" }, listing)!;
    assert.equal(d.to, "u2");
    assert.equal(d.route, "/chats/l1_u2_1");
    assert.equal(d.record?.actorName, "Dilshod A.");
    assert.equal(d.record?.chatId, "l1_u2_1");
  });

  it("a rejection tells how many attempts are left", () => {
    const d = claimUpdated("l1_u2_2", claim, { ...claim, attempt: 2, status: "rejected" }, listing)!;
    assert.equal(d.to, "u2");
    assert.equal(d.route, "/listing/l1");
    assert.equal(d.record?.attemptsLeft, 1);
    const last = claimUpdated("l1_u2_3", claim, { ...claim, attempt: 3, status: "rejected" }, listing)!;
    assert.equal(last.record?.attemptsLeft, 0);
  });

  it("only a pending → answered change notifies", () => {
    assert.equal(claimUpdated("c", claim, claim, listing), null);
    assert.equal(claimUpdated("c", { ...claim, status: "accepted" }, { ...claim, status: "rejected" }, listing), null);
  });

  it("a claim on one's own listing notifies nobody", () => {
    assert.equal(claimCreated({ ...claim, claimantId: "u1" }, listing), null);
  });
});

describe("messages", () => {
  it("a text goes to the other member only, not on the page", () => {
    const d = messageCreated("c1", { senderId: "u2", kind: "text", text: "Salom" }, chat)!;
    assert.equal(d.to, "u1");
    assert.equal(d.route, "/chats/c1");
    assert.equal(d.threadId, "c1");
    assert.equal(d.record, undefined);
    assert.deepEqual(pushText(d.push, "uz_Latn"), { title: "Malika K.", body: "Salom" });
  });

  it("“returned” goes to the owner and opens the success screen", () => {
    const d = messageCreated("c1", { senderId: "u1", kind: "returned", text: "x" }, chat)!;
    assert.equal(d.to, "u2");
    assert.equal(d.route, "/success/c1");
    assert.equal(d.record?.kind, "returned");
    assert.equal(d.record?.actorName, "Dilshod A.");
  });

  it("a sender outside the chat, or no chat, notifies nobody", () => {
    assert.equal(messageCreated("c1", { senderId: "u9", kind: "text", text: "x" }, chat), null);
    assert.equal(messageCreated("c1", { senderId: "u1", kind: "text", text: "x" }, undefined), null);
  });
});

describe("texts", () => {
  it("each language has its own text", () => {
    const c = { kind: "claimRejected", listingTitle: "Pasport", attemptsLeft: 2 } as const;
    assert.equal(pushText(c, "uz_Latn").body, "“Pasport” boʻyicha soʻrovingiz rad etildi. Yana 2 ta urinishingiz bor.");
    assert.equal(pushText(c, "uz_Cyrl").body, "“Pasport” бўйича сўровингиз рад этилди. Яна 2 та уринишингиз бор.");
    assert.equal(pushText(c, "ru").body, "Ваша заявка по «Pasport» отклонена. Осталось попыток: 2.");
    assert.equal(pushText({ ...c, attemptsLeft: 0 }, "uz_Latn").body, "“Pasport” boʻyicha soʻrovingiz rad etildi.");
  });

  it("unknown language falls back to Uzbek Latin", () => {
    assert.equal(langOf("en"), "uz_Latn");
    assert.equal(langOf(undefined), "uz_Latn");
    assert.equal(langOf("ru"), "ru");
  });

  it("long messages are shortened on one line", () => {
    assert.equal(shorten("a\n  b"), "a b");
    const s = shorten("x".repeat(200));
    assert.equal(Array.from(s).length, 80);
    assert.ok(s.endsWith("…"));
  });
});

describe("payload", () => {
  it("carries the route and groups by chat", () => {
    const d = messageCreated("c1", { senderId: "u2", kind: "text", text: "Salom" }, chat)!;
    const m = multicast(["t1", "t2"], { title: "A", body: "B" }, d);
    assert.deepEqual(m.tokens, ["t1", "t2"]);
    assert.deepEqual(m.data, { route: "/chats/c1" });
    assert.equal(m.apns?.payload?.aps.threadId, "c1");
    assert.equal(m.apns?.payload?.aps.sound, "default");
  });

  it("no thread id when there is no chat", () => {
    const m = multicast(["t"], { title: "A", body: "B" }, claimCreated(claim, listing)!);
    assert.equal("threadId" in (m.apns?.payload?.aps ?? {}), false);
  });
});

describe("reminders", () => {
  const w = (id: string, listingId: string, to: string) => ({ id, listingId, listingAuthorId: to, listingTitle: `T${listingId}` });

  it("one push per author; one listing opens its claims", () => {
    const ds = reminders([w("a", "l1", "u1"), w("b", "l1", "u1")]);
    assert.equal(ds.length, 1);
    assert.equal(ds[0].to, "u1");
    assert.equal(ds[0].route, "/listing/l1/claims");
    assert.deepEqual(ds[0].push, { kind: "reminder", count: 2, listingTitle: "Tl1" });
    assert.equal(ds[0].record, undefined);
  });

  it("several listings go to the Profil tab", () => {
    const ds = reminders([w("a", "l1", "u1"), w("b", "l2", "u1"), w("c", "l3", "u2")]);
    assert.equal(ds.length, 2);
    const u1 = ds.find((d) => d.to === "u1")!;
    assert.equal(u1.route, "/profile");
    assert.equal(pushText(u1.push, "uz_Latn").title, "Sizni 2 ta soʻrov kutyapti");
    assert.equal(pushText(ds.find((d) => d.to === "u2")!.push, "ru").title, "Вас ждёт заявка");
  });
});
