/**
 * Topildi push notifications. Deployed as its own codebase ("topildi" in
 * firebase.json) because the Firebase project is shared with FoodZeen:
 * `firebase deploy --only functions:topildi` never touches FoodZeen's
 * functions. Names are prefixed for the same reason (they are project-wide).
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";

import { claimCreated, claimUpdated, Delivery, messageCreated } from "./events";
import { deliver } from "./notify";

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
