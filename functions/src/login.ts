/**
 * Telegram sign-in on Firestore and Auth (logic in telegram.ts).
 *
 * topildi_tg_sessions/{sid}: one sign-in attempt (see Session).
 * topildi_tg_chats/{chatId}: the sid a bot chat is answering, so the shared
 * contact (which carries no payload) finds its session
 * Both are server-only (firestore.rules).
 */
import { createHash, randomBytes, timingSafeEqual } from "node:crypto";

import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError } from "firebase-functions/v2/https";

import { paths } from "./notify";
import { checkContact, fallbackName, Incoming, reply, Session, sessionState, sessionTtlMs } from "./telegram";

export const tgPaths = {
  sessions: "topildi_tg_sessions",
  chats: "topildi_tg_chats",
} as const;

const db = () => getFirestore();
const sessions = () => db().collection(tgPaths.sessions);
const chats = () => db().collection(tgPaths.chats);

const token = (bytes: number) => randomBytes(bytes).toString("base64url");
const sha256 = (s: string) => createHash("sha256").update(s).digest();

/** A new attempt: the app keeps the secret and opens the bot with the sid. */
export async function startSession(botUsername: string) {
  const sid = token(16);
  const secret = token(32);
  const session: Session = {
    secretHash: sha256(secret).toString("hex"),
    status: "pending",
    expiresAt: Date.now() + sessionTtlMs,
  };
  await sessions().doc(sid).set(session);
  return { sid, secret, url: `https://t.me/${botUsername}?start=${sid}` };
}

/**
 * The app asks every few seconds. Pending → `{ status: "pending" }`;
 * verified → a custom token for the Auth user with that phone number (the
 * same user an earlier SMS sign-in created), and the session is spent.
 * A first sign-in also gets its profile, named after the Telegram account,
 * so the app goes straight to the feed.
 */
export async function claimSession(sid: unknown, secret: unknown) {
  if (typeof sid !== "string" || typeof secret !== "string" || !sid || !secret) {
    throw new HttpsError("invalid-argument", "sid and secret are required");
  }
  const ref = sessions().doc(sid);
  const s = (await ref.get()).data() as Session | undefined;
  const expected = Buffer.from(s?.secretHash ?? "", "hex");
  const given = sha256(secret);
  if (!s || expected.length !== given.length || !timingSafeEqual(expected, given)) {
    throw new HttpsError("not-found", "session");
  }
  const state = sessionState(s, Date.now());
  if (state === "missing" || state === "expired") throw new HttpsError("not-found", "session");
  if (state === "pending") return { status: "pending" as const };

  const phone = s.phone!;
  const uid = await uidFor(phone);
  await ensureProfile(uid, s.name ?? fallbackName);
  const customToken = await getAuth().createCustomToken(uid);
  await ref.delete();
  return { status: "verified" as const, token: customToken, phone };
}

/**
 * Creates topildi_users/{uid} (the shape firestore.rules allows) unless it
 * already has a name: returning users keep theirs.
 */
async function ensureProfile(uid: string, firstName: string) {
  const ref = db().collection(paths.users).doc(uid);
  await db().runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    const current = doc.data()?.firstName;
    if (typeof current === "string" && current.trim()) return;
    tx.set(
      ref,
      {
        firstName,
        avatarUrl: null,
        avatarEmoji: null,
        avatarTone: 0,
        updatedAt: FieldValue.serverTimestamp(),
        ...(doc.exists ? {} : { createdAt: FieldValue.serverTimestamp(), returnedCount: 0 }),
      },
      { merge: true },
    );
  });
}

async function uidFor(phoneNumber: string): Promise<string> {
  try {
    return (await getAuth().getUserByPhoneNumber(phoneNumber)).uid;
  } catch (e) {
    if ((e as { code?: string }).code !== "auth/user-not-found") throw e;
    return (await getAuth().createUser({ phoneNumber })).uid;
  }
}

/** Handles one bot update; returns the reply (sent as the webhook response). */
export async function handleUpdate(m: Incoming) {
  const now = Date.now();
  switch (m.kind) {
    case "start": {
      const s = (await sessions().doc(m.sid).get()).data() as Session | undefined;
      if (sessionState(s, now) !== "pending") return reply(m.chatId, m.lang, "expired");
      await chats().doc(String(m.chatId)).set({ sid: m.sid });
      return reply(m.chatId, m.lang, "askContact", true);
    }
    case "contact": {
      const chat = chats().doc(String(m.chatId));
      const sid = (await chat.get()).data()?.sid;
      if (typeof sid !== "string") return reply(m.chatId, m.lang, "openApp");
      const ref = sessions().doc(sid);
      const s = (await ref.get()).data() as Session | undefined;
      if (sessionState(s, now) !== "pending") {
        await chat.delete();
        return reply(m.chatId, m.lang, "expired");
      }
      const check = checkContact(m);
      if (!check.ok) return reply(m.chatId, m.lang, check.reason, check.reason === "foreign");
      await ref.update({ status: "verified", phone: check.phone, name: m.name });
      await chat.delete();
      logger.info("Telegram sign-in verified", { sid });
      return reply(m.chatId, m.lang, "verified");
    }
    case "other": {
      const sid = (await chats().doc(String(m.chatId)).get()).data()?.sid;
      const s = typeof sid === "string" ? ((await sessions().doc(sid).get()).data() as Session | undefined) : undefined;
      return sessionState(s, now) === "pending"
        ? reply(m.chatId, m.lang, "askContact", true)
        : reply(m.chatId, m.lang, "openApp");
    }
  }
}
