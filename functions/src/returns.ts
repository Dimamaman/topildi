/**
 * Who returned an item, and whether they may be named for it.
 *
 * `topildi_listings/{id}.finderDisplayName` is the only name the
 * "Egasiga qaytdi" strip and its stories ever show, and only the server
 * writes it (firestore.rules): the app may change nothing but its own
 * `topildi_users/{uid}.showNameOnReturns`, which is off unless the person
 * turned it on. The owner is never named, with consent or without.
 *
 * `topildi_returns/{listingId}` keeps the link between a returned listing and
 * the person who returned it. It is server-only, so that taking consent back
 * can find every listing again without the uid of a finder ever sitting on a
 * document the whole app can read.
 */
import { FieldValue, getFirestore } from "firebase-admin/firestore";

export type Doc = Record<string, unknown>;

export const returnPaths = {
  listings: "topildi_listings",
  chats: "topildi_chats",
  users: "topildi_users",
  returns: "topildi_returns",
} as const;

/** Firestore refuses a batch over 500 writes. */
const batchSize = 400;

const str = (v: unknown): string => (typeof v === "string" ? v : "");

export type Finder = { uid: string; name: string };

/**
 * The person who handed the item over, as the closing write names them: from
 * the chat of the accepted claim, or — for a "found" listing its author
 * closed alone — the author. A "lost" listing closed without a chat has no
 * finder to name.
 */
export function finderOf(listing: Doc, chat: Doc | undefined): Finder | null {
  const fromChat = str(chat?.finderId);
  if (fromChat) {
    const names = (chat?.names ?? {}) as Record<string, unknown>;
    return { uid: fromChat, name: str(names[fromChat]) };
  }
  if (listing.type !== "found") return null;
  const uid = str(listing.authorId);
  return uid ? { uid, name: str(listing.authorName) } : null;
}

/** What `finderDisplayName` should hold: the name, or nothing at all. */
export function displayName(finder: Finder, consented: boolean): string | null {
  return consented && finder.name ? finder.name : null;
}

/**
 * A listing was just closed as returned: remember who returned it and write
 * their name onto it if they have already allowed it.
 *
 * The write below lands as another update of the same listing; its `before`
 * and `after` then carry the same status, so this returns at the first line.
 */
export async function listingReturned(listingId: string, before: Doc, after: Doc): Promise<void> {
  if (after.status !== "returned" || before.status === "returned") return;
  const db = getFirestore();
  const chatId = str(after.returnedViaChat);
  const chat = chatId ? (await db.collection(returnPaths.chats).doc(chatId).get()).data() : undefined;
  const finder = finderOf(after, chat);
  if (!finder) return;

  const consented = (await db.collection(returnPaths.users).doc(finder.uid).get()).get("showNameOnReturns") === true;
  await db.collection(returnPaths.returns).doc(listingId).set({
    listingId,
    finderId: finder.uid,
    finderName: finder.name,
    returnedAt: FieldValue.serverTimestamp(),
  });
  await setDisplayName(listingId, displayName(finder, consented));
}

/**
 * The switch moved in the app: every item this person returned gains or
 * loses their name at once, so the story and the setting never disagree.
 */
export async function consentChanged(uid: string, before: Doc, after: Doc): Promise<number> {
  const was = before.showNameOnReturns === true;
  const now = after.showNameOnReturns === true;
  if (was === now) return 0;
  const db = getFirestore();
  const mine = await db.collection(returnPaths.returns).where("finderId", "==", uid).get();
  const listings = db.collection(returnPaths.listings);
  for (let i = 0; i < mine.docs.length; i += batchSize) {
    const batch = db.batch();
    for (const doc of mine.docs.slice(i, i + batchSize)) {
      const name = str(doc.get("finderName"));
      batch.update(listings.doc(str(doc.get("listingId")) || doc.id), {
        finderDisplayName: now && name ? name : FieldValue.delete(),
      });
    }
    await batch.commit();
  }
  return mine.size;
}

/** A missing listing is not an error here: it may have been deleted. */
async function setDisplayName(listingId: string, name: string | null): Promise<void> {
  try {
    await getFirestore()
      .collection(returnPaths.listings)
      .doc(listingId)
      .update({ finderDisplayName: name ?? FieldValue.delete() });
  } catch {
    // Nothing left to name.
  }
}
