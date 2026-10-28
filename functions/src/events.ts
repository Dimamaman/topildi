/**
 * Who hears about what. Pure functions from the written documents to
 * deliveries, so they are tested without Firestore (src/test/).
 *
 * Document shapes: lib/features/claim/data/models/claim_firestore.dart and
 * lib/features/chat/data/models/chat_firestore.dart; rules in firestore.rules.
 */
import { PushContent } from "./texts";

export type Doc = Record<string, unknown>;

/** Stored in topildi_users/{uid}/notifications; read by notification_firestore.dart. */
export type NotificationRecord = {
  kind: "newClaim" | "claimAccepted" | "claimRejected" | "returned";
  listingId: string;
  listingTitle: string;
  chatId?: string;
  actorName?: string;
  attemptsLeft?: number;
};

export type Delivery = {
  to: string;
  push: PushContent;
  /** App route the push opens (lib/app/routes.dart). */
  route: string;
  /** Groups a chat's pushes on the lock screen. */
  threadId?: string;
  /** Also listed on the Bildirishnomalar page; chat messages are not. */
  record?: NotificationRecord;
};

/** Claim attempts per person per listing (see firestore.rules). */
export const maxAttempts = 3;

const str = (v: unknown): string => (typeof v === "string" ? v : "");
const num = (v: unknown): number => (typeof v === "number" ? v : 0);

/** A new claim: the listing's author checks the answer. */
export function claimCreated(claim: Doc, listing: Doc | undefined): Delivery | null {
  const to = str(claim.listingAuthorId);
  const listingId = str(claim.listingId);
  if (!to || !listingId || to === claim.claimantId) return null;
  const listingTitle = str(listing?.title);
  return {
    to,
    push: { kind: "newClaim", listingTitle },
    route: `/listing/${listingId}/claims`,
    record: { kind: "newClaim", listingId, listingTitle },
  };
}

/** The author answered: the claimant hears either way. */
export function claimUpdated(claimId: string, before: Doc, after: Doc, listing: Doc | undefined): Delivery | null {
  if (before.status !== "pending" || before.status === after.status) return null;
  const to = str(after.claimantId);
  const listingId = str(after.listingId);
  if (!to || !listingId) return null;
  const listingTitle = str(listing?.title);
  if (after.status === "accepted") {
    // The chat has the claim's id and is created in the same batch.
    const actorName = str(listing?.authorName);
    return {
      to,
      push: { kind: "claimAccepted", actorName },
      route: `/chats/${claimId}`,
      threadId: claimId,
      record: { kind: "claimAccepted", listingId, listingTitle, chatId: claimId, actorName },
    };
  }
  if (after.status === "rejected") {
    const attemptsLeft = Math.max(0, maxAttempts - num(after.attempt));
    return {
      to,
      push: { kind: "claimRejected", listingTitle, attemptsLeft },
      route: `/listing/${listingId}`,
      record: { kind: "claimRejected", listingId, listingTitle, attemptsLeft },
    };
  }
  return null;
}

/** Claims left unanswered this long get one reminder to the author. */
export const remindAfterMs = 24 * 60 * 60 * 1000;

/** A pending claim that is due a reminder, with its listing's title. */
export type WaitingClaim = { id: string; listingId: string; listingAuthorId: string; listingTitle: string };

/**
 * One reminder per author for all their waiting claims: to the claims of
 * that listing when they are all on one, otherwise to the Profil tab
 * (which lists claims waiting per listing). Not listed on the page: the
 * "newClaim" notification is already there.
 */
export function reminders(waiting: WaitingClaim[]): Delivery[] {
  const byAuthor = new Map<string, WaitingClaim[]>();
  for (const c of waiting) {
    if (!c.listingAuthorId || !c.listingId) continue;
    byAuthor.set(c.listingAuthorId, [...(byAuthor.get(c.listingAuthorId) ?? []), c]);
  }
  return [...byAuthor].map(([to, claims]) => {
    const listings = new Set(claims.map((c) => c.listingId));
    const one = listings.size === 1 ? claims[0] : undefined;
    return {
      to,
      push: { kind: "reminder", count: claims.length, listingTitle: one?.listingTitle },
      route: one ? `/listing/${one.listingId}/claims` : "/profile",
    };
  });
}

/** A chat message reaches the other member; "returned" also goes on the page. */
export function messageCreated(chatId: string, message: Doc, chat: Doc | undefined): Delivery | null {
  if (!chat) return null;
  const from = str(message.senderId);
  const members = Array.isArray(chat.members) ? chat.members.map(str) : [];
  const to = members.find((m) => m && m !== from);
  if (!from || !to || !members.includes(from)) return null;
  const names = (chat.names ?? {}) as Doc;
  const actorName = str(names[from]);
  if (message.kind === "returned") {
    const listingId = str(chat.listingId);
    const listingTitle = str(chat.listingTitle);
    return {
      to,
      push: { kind: "returned", actorName },
      route: `/success/${chatId}`,
      threadId: chatId,
      record: { kind: "returned", listingId, listingTitle, chatId, actorName },
    };
  }
  if (message.kind !== "text") return null;
  return {
    to,
    push: { kind: "message", actorName, text: str(message.text) },
    route: `/chats/${chatId}`,
    threadId: chatId,
  };
}
