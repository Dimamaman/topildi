/**
 * Topildi push notifications and Telegram sign-in. Deployed as its own codebase ("topildi" in
 * firebase.json) because the Firebase project is shared with FoodZeen:
 * `firebase deploy --only functions:topildi` never touches FoodZeen's
 * functions. Names are prefixed for the same reason (they are project-wide).
 */
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { defineSecret, defineString } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { deleteAccount } from "./account";
import { claimCreated, claimUpdated, Delivery, messageCreated, remindAfterMs, reminders, WaitingClaim } from "./events";
import { errorMessage, errorRateDay, maxErrorsPerDay, parseErrorReport } from "./errors";
import { claimSession, handleUpdate, startSession } from "./login";
import { BotConfig, callBot, handleModeration, handleReport } from "./moderate";
import { deliver } from "./notify";
import { isReopened, parseCallbackData, ReportDoc } from "./report";
import { parseCallback, parseUpdate, TgUpdate } from "./telegram";

initializeApp();

/** Must be the Firestore database's location (Firebase Console → Firestore). */
const region = "us-central1";

setGlobalOptions({ region, maxInstances: 10 });

async function listing(id: unknown) {
  if (typeof id !== "string" || !id) return undefined;
  return (await getFirestore().collection("topildi_listings").doc(id).get()).data();
}

async function send(eventId: string, d: Delivery | null) {
  if (d) await deliver(eventId, d);
}

export const topildiOnClaimCreated = onDocumentCreated("topildi_claims/{claimId}", async (event) => {
  const claim = event.data?.data();
  if (!claim) return;
  await send(event.id, claimCreated(claim, await listing(claim.listingId)));
});

export const topildiOnClaimUpdated = onDocumentUpdated("topildi_claims/{claimId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;
  await send(event.id, claimUpdated(event.params.claimId, before, after, await listing(after.listingId)));
});

export const topildiOnMessageCreated = onDocumentCreated(
  "topildi_chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data?.data();
    if (!message) return;
    const chat = (await getFirestore().collection("topildi_chats").doc(event.params.chatId).get()).data();
    await send(event.id, messageCreated(event.params.chatId, message, chat));
  },
);

/**
 * Hourly: claims pending for over a day get one reminder to the listing's
 * author (`remindedAt` marks them; the app never reads it).
 */
export const topildiRemindPendingClaims = onSchedule("every 60 minutes", async (event) => {
  const db = getFirestore();
  const cutoff = Timestamp.fromMillis(Date.now() - remindAfterMs);
  const snap = await db
    .collection("topildi_claims")
    .where("status", "==", "pending")
    .where("createdAt", "<=", cutoff)
    .get();
  const due = snap.docs.filter((d) => d.get("remindedAt") === undefined);
  if (due.length === 0) return;

  const titles = new Map<string, string>();
  const waiting: WaitingClaim[] = [];
  for (const d of due) {
    const listingId = d.get("listingId") as string;
    if (!titles.has(listingId)) titles.set(listingId, String((await listing(listingId))?.title ?? ""));
    waiting.push({
      id: d.id,
      listingId,
      listingAuthorId: d.get("listingAuthorId") as string,
      listingTitle: titles.get(listingId) ?? "",
    });
  }
  // Marked first: a failed push is not retried every hour.
  const batch = db.batch();
  for (const d of due) batch.update(d.ref, { remindedAt: Timestamp.now() });
  await batch.commit();
  for (const d of reminders(waiting)) {
    await send(`remind_${event.scheduleTime}_${d.to}`, d);
  }
});

/** Bot username without "@" (functions/.env), for the t.me link. */
const botUsername = defineString("TELEGRAM_BOT_USERNAME");

/** Moderator chat for shikoyatlar (functions/.env); empty turns sending off. */
const adminChatId = defineString("TELEGRAM_ADMIN_CHAT_ID", { default: "" });

/**
 * Where app errors go (functions/.env); empty falls back to the moderator
 * chat, and an empty moderator chat turns error reports off.
 */
const errorsChatId = defineString("TELEGRAM_ERRORS_CHAT_ID", { default: "" });

/**
 * Bot token, for the calls the bot makes by itself (the sign-in replies ride
 * back in the webhook's response and need none).
 */
const botToken = defineSecret("TELEGRAM_BOT_TOKEN");

const botConfig = (): BotConfig => ({ token: botToken.value(), adminChatId: adminChatId.value() });

/**
 * A shikoyat from the app (report.ts, moderate.ts): the evidence is copied
 * onto the report, the moderator chat hears about it, and a listing three
 * different people reported is hidden.
 */
export const topildiOnReportCreated = onDocumentCreated(
  { document: "topildi_reports/{reportId}", secrets: [botToken] },
  async (event) => {
    const report = event.data?.data() as ReportDoc | undefined;
    if (!report) return;
    await handleReport(event.params.reportId, report, botConfig());
  },
);

/**
 * The same shikoyat sent again after the moderator closed it. A separate
 * trigger rather than onDocumentWritten, so the create above keeps its name
 * and no function is deleted and made again on deploy.
 */
export const topildiOnReportReopened = onDocumentUpdated(
  { document: "topildi_reports/{reportId}", secrets: [botToken] },
  async (event) => {
    const after = event.data?.after.data();
    if (!after || !isReopened(event.data?.before.data(), after)) return;
    await handleReport(event.params.reportId, after as ReportDoc, botConfig());
  },
);

/** Passed to setWebhook as secret_token; Telegram sends it back in a header. */
const webhookSecret = defineSecret("TELEGRAM_WEBHOOK_SECRET");

export const topildiTgStart = onCall(() => startSession(botUsername.value()));

export const topildiTgClaim = onCall((req) => claimSession(req.data?.sid, req.data?.secret));

export const topildiTgWebhook = onRequest({ secrets: [webhookSecret, botToken] }, async (req, res) => {
  if (req.method !== "POST" || req.get("X-Telegram-Bot-Api-Secret-Token") !== webhookSecret.value()) {
    res.status(403).end();
    return;
  }
  // A moderator's button under a shikoyat: answered through the Bot API, so
  // the webhook's own response stays empty.
  const press = parseCallback(req.body as TgUpdate);
  if (press) {
    const picked = parseCallbackData(press.data);
    try {
      if (picked) await handleModeration({ ...press, ...picked }, botConfig());
    } catch (e) {
      logger.error("Moderation press failed", e);
    }
    res.status(200).end();
    return;
  }
  const m = parseUpdate(req.body as TgUpdate);
  if (!m) {
    res.status(200).end();
    return;
  }
  try {
    res.status(200).json(await handleUpdate(m));
  } catch (e) {
    // A 200 anyway: Telegram would otherwise resend the update for hours.
    logger.error("Telegram update failed", e);
    res.status(200).end();
  }
});

/**
 * An error the app ran into (lib/core/error/error_reporter.dart): the
 * developer chat gets the page, the message and the stack. The app never
 * holds the bot token, and nothing is written to Firestore except the
 * counter that caps a runaway day.
 */
export const topildiLogError = onCall({ secrets: [botToken] }, async (req) => {
  const chatId = errorsChatId.value() || adminChatId.value();
  if (!chatId) return { sent: false };
  const report = parseErrorReport(req.data, req.auth?.uid);
  if (!report) throw new HttpsError("invalid-argument", "message required");
  const ref = getFirestore().collection("topildi_error_rate").doc(errorRateDay());
  // Read then increment: two errors at the very same moment may share a
  // slot, which costs one message over the cap and saves a transaction.
  const sentToday = Number((await ref.get()).get("count") ?? 0);
  if (sentToday >= maxErrorsPerDay) return { sent: false, limited: true };
  await ref.set({ count: FieldValue.increment(1), day: errorRateDay() }, { merge: true });
  try {
    await callBot(botConfig(), "sendMessage", {
      chat_id: chatId,
      text: errorMessage(report),
      parse_mode: "HTML",
      disable_web_page_preview: true,
    });
  } catch (e) {
    // The app is already in trouble; it must not be told about ours.
    logger.error("Error report failed", e);
    return { sent: false };
  }
  return { sent: true };
});

/** Profil → "Hisobni oʻchirish" (account.ts). Only the signed-in user themself. */
export const topildiDeleteAccount = onCall({ timeoutSeconds: 300 }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "sign in first");
  return deleteAccount(uid);
});
