/**
 * Firestore and Bot API side of a shikoyat: copy the evidence onto the
 * report, tell the moderator chat about it, hide a listing three different
 * people reported, and carry out the moderator's button presses.
 *
 * The texts and the shape of it all are pure functions in report.ts.
 */
import { randomBytes } from "node:crypto";

import { FieldPath, FieldValue, getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions";

import { paths } from "./notify";
import {
  Evidence,
  hideThreshold,
  maxEvidenceMessages,
  ModerationAction,
  moderationKeyboard,
  modKeyLength,
  moderationNote,
  ReportDoc,
  reportMessage,
  statusAfter,
} from "./report";

/**
 * The key a moderator button carries instead of the report id, which is too
 * long for callback_data (see modKeyLength in report.ts). Stored on the
 * report as `modKey` and read back when the button is pressed.
 */
export function newModKey(): string {
  return randomBytes(9).toString("base64url").slice(0, modKeyLength);
}

export const reportPaths = {
  reports: "topildi_reports",
  listings: "topildi_listings",
  chats: "topildi_chats",
  messages: "messages",
} as const;

/** Bot token and moderator chat, from functions/.env and Secret Manager. */
export type BotConfig = { token: string; adminChatId: string };

/**
 * One Bot API call. The webhook's own replies ride back in its response
 * (telegram.ts) and need no token; these do, because nothing asked for them.
 */
export async function callBot(cfg: BotConfig, method: string, body: Record<string, unknown>): Promise<unknown> {
  const res = await fetch(`https://api.telegram.org/bot${cfg.token}/${method}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const json = (await res.json()) as { ok?: boolean; description?: string; result?: unknown };
  if (!json.ok) throw new Error(`${method}: ${json.description ?? res.status}`);
  return json.result;
}

const str = (v: unknown): string => (typeof v === "string" ? v : "");

function listingEvidence(d: FirebaseFirestore.DocumentData): Evidence {
  const lines = [str(d.description), [str(d.areaName), str(d.district), str(d.city)].filter(Boolean).join(" · ")];
  return {
    title: str(d.title),
    lines: lines.filter((l) => l.length > 0),
    photoUrls: Array.isArray(d.photoUrls) ? d.photoUrls.map(str).filter(Boolean) : [],
  };
}

/** The last [maxEvidenceMessages] messages, oldest first, as "Name: text". */
async function chatEvidence(db: FirebaseFirestore.Firestore, chatId: string): Promise<Evidence | undefined> {
  const chat = (await db.collection(reportPaths.chats).doc(chatId).get()).data();
  if (!chat) return undefined;
  const snap = await db
    .collection(reportPaths.chats)
    .doc(chatId)
    .collection(reportPaths.messages)
    .orderBy("createdAt", "desc")
    .limit(maxEvidenceMessages)
    .get();
  const names = (chat.names ?? {}) as Record<string, unknown>;
  const lines = snap.docs
    .reverse()
    .map((m) => `${str(names[str(m.get("senderId"))]) || str(m.get("senderId"))}: ${str(m.get("text"))}`);
  return { title: str(chat.listingTitle), lines };
}

export async function evidenceOf(
  db: FirebaseFirestore.Firestore,
  report: ReportDoc,
): Promise<Evidence | undefined> {
  if (report.targetType === "listing") {
    const d = (await db.collection(reportPaths.listings).doc(report.targetId).get()).data();
    return d ? listingEvidence(d) : undefined;
  }
  return chatEvidence(db, report.targetId);
}

/**
 * Reports on the same target, counted by their ids
 * ({targetType}_{targetId}_{reporterUid}), so no composite index is needed.
 */
export async function reportCount(
  db: FirebaseFirestore.Firestore,
  targetType: string,
  targetId: string,
): Promise<number> {
  const prefix = `${targetType}_${targetId}_`;
  const snap = await db
    .collection(reportPaths.reports)
    .orderBy(FieldPath.documentId())
    .startAt(prefix)
    .endAt(`${prefix}`)
    .get();
  return snap.size;
}

async function displayName(db: FirebaseFirestore.Firestore, uid: string): Promise<string> {
  if (!uid) return "";
  return str((await db.collection(paths.users).doc(uid).get()).get("firstName"));
}

/** A listing only the server may hide; the author never sees the status. */
async function setListingStatus(
  db: FirebaseFirestore.Firestore,
  listingId: string,
  status: "hidden" | "active",
): Promise<void> {
  await db
    .collection(reportPaths.listings)
    .doc(listingId)
    .update({ status, updatedAt: FieldValue.serverTimestamp() });
}

/**
 * A new report: keep the evidence, tell the moderator, and hide a listing
 * that [hideThreshold] different people have now reported.
 */
export async function handleReport(reportId: string, report: ReportDoc, cfg: BotConfig): Promise<void> {
  const db = getFirestore();
  const evidence = await evidenceOf(db, report);
  const count = await reportCount(db, report.targetType, report.targetId);
  const modKey = newModKey();
  // On the report itself: the listing or the chat may be gone by the time a
  // moderator looks, the copy stays.
  await db
    .collection(reportPaths.reports)
    .doc(reportId)
    .set({ evidence: evidence ?? null, reports: count, modKey }, { merge: true });

  const hide = report.targetType === "listing" && count >= hideThreshold;
  if (hide) {
    try {
      await setListingStatus(db, report.targetId, "hidden");
    } catch (e) {
      logger.error("Could not hide the reported listing", { listingId: report.targetId, e });
    }
  }

  if (!cfg.token || !cfg.adminChatId) {
    logger.warn("No TELEGRAM_BOT_TOKEN / TELEGRAM_ADMIN_CHAT_ID: the report was not sent", { reportId });
    return;
  }
  const [reporter, reported] = await Promise.all([
    displayName(db, report.reporterId),
    displayName(db, report.reportedUid),
  ]);
  const text = reportMessage(reportId, report, evidence, { reporter, reported }, count);
  await callBot(cfg, "sendMessage", {
    chat_id: cfg.adminChatId,
    text: hide ? `${text}\n\n🙈 <b>Avtomatik yashirildi</b>` : text,
    parse_mode: "HTML",
    link_preview_options: { is_disabled: true },
    reply_markup: moderationKeyboard(modKey, report.targetType),
  });
}

export type ModerationPress = {
  callbackId: string;
  /** The chat the message with the buttons is in — the moderator chat. */
  chatId: number;
  messageId: number;
  action: ModerationAction;
  /** The report's short key, as the button carried it. */
  modKey: string;
};

/**
 * A button under a moderator message. Only presses from the moderator chat
 * count; anything else is answered and dropped.
 */
export async function handleModeration(press: ModerationPress, cfg: BotConfig): Promise<void> {
  const answer = (text: string) =>
    callBot(cfg, "answerCallbackQuery", { callback_query_id: press.callbackId, text });
  if (String(press.chatId) !== cfg.adminChatId) {
    await answer("Ruxsat yoʻq");
    return;
  }
  const db = getFirestore();
  // A single-field equality, so Firestore's automatic index is enough.
  const snap = await db
    .collection(reportPaths.reports)
    .where("modKey", "==", press.modKey)
    .limit(1)
    .get();
  const doc = snap.docs[0];
  if (!doc) {
    await answer("Shikoyat topilmadi");
    return;
  }
  const ref = doc.ref;
  const report = doc.data();
  if (press.action !== "close" && report.targetType === "listing") {
    await setListingStatus(db, str(report.targetId), press.action === "hide" ? "hidden" : "active");
  }
  await ref.update({
    status: statusAfter(press.action),
    moderatedAt: FieldValue.serverTimestamp(),
  });
  const note = moderationNote(press.action);
  await answer(note);
  // The buttons go: the message keeps the facts plus what was decided.
  await callBot(cfg, "editMessageReplyMarkup", {
    chat_id: press.chatId,
    message_id: press.messageId,
    reply_markup: { inline_keyboard: [[{ text: note, callback_data: "r:done" }]] },
  });
}
