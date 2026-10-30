/**
 * "Hisobni oʻchirish": removes everything Topildi keeps about a user.
 *
 * The Firebase project (and so Auth) is shared with FoodZeen, and a Telegram
 * sign-in reuses the Auth user that has the same phone number. The Auth user
 * is therefore deleted only when FoodZeen has nothing under it; otherwise it
 * stays, with no Topildi data left, and its sessions are revoked.
 */
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { logger } from "firebase-functions";

import { paths } from "./notify";

export const accountPaths = {
  listings: "topildi_listings",
  claims: "topildi_claims",
  chats: "topildi_chats",
  /** FoodZeen's profiles: `users/{uid}`, `users/{uid}/recipes`. */
  foodzeenUsers: "users",
} as const;

/** Storage folders to empty: the user's own and those of their listings and claims. */
export function storagePrefixes(uid: string, listingIds: string[], claimIds: string[]): string[] {
  return [
    `topildi/uploads/${uid}/`,
    `topildi/users/${uid}/`,
    ...listingIds.map((id) => `topildi/listings/${id}/`),
    ...claimIds.map((id) => `topildi/claims/${id}/`),
  ];
}

export async function deleteAccount(uid: string): Promise<{ authDeleted: boolean }> {
  const db = getFirestore();
  const ids = async (collection: string, field: string, op: "==" | "array-contains" = "==") =>
    (await db.collection(collection).where(field, op, uid).get()).docs.map((d) => d.ref);

  const listings = await ids(accountPaths.listings, "authorId");
  // Claims the user sent, and claims others sent on the user's listings.
  const claims = [...(await ids(accountPaths.claims, "claimantId")), ...(await ids(accountPaths.claims, "listingAuthorId"))];
  const chats = await ids(accountPaths.chats, "members", "array-contains");

  const bucket = getStorage().bucket();
  for (const prefix of storagePrefixes(uid, listings.map((r) => r.id), claims.map((r) => r.id))) {
    await bucket.deleteFiles({ prefix });
  }

  // Recursive: messages, the hidden detail, devices and notifications go too.
  for (const ref of [...chats, ...claims, ...listings, db.collection(paths.users).doc(uid)]) {
    await db.recursiveDelete(ref);
  }

  const foodzeen = db.collection(accountPaths.foodzeenUsers).doc(uid);
  const usedByFoodzeen =
    (await foodzeen.get()).exists || !(await foodzeen.collection("recipes").limit(1).get()).empty;
  try {
    if (usedByFoodzeen) {
      await getAuth().revokeRefreshTokens(uid);
    } else {
      await getAuth().deleteUser(uid);
    }
  } catch (e) {
    if ((e as { code?: string }).code !== "auth/user-not-found") throw e;
  }
  logger.info("Account deleted", {
    uid,
    listings: listings.length,
    claims: claims.length,
    chats: chats.length,
    authDeleted: !usedByFoodzeen,
  });
  return { authDeleted: !usedByFoodzeen };
}
