import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions";

import type { Delivery } from "./events";
import { multicast, staleTokenErrors } from "./payload";
import { Lang, langOf, pushText } from "./texts";

/** Same names as FirePaths in lib/core/di/firebase_module.dart. */
export const paths = {
  users: "topildi_users",
  notifications: "notifications",
  devices: "devices",
} as const;

/** gRPC ALREADY_EXISTS. */
const alreadyExists = 6;

/**
 * Stores the notification (if it has a record) under the trigger's event id,
 * so a retried event neither lists nor pushes twice, then pushes to every
 * device of the recipient in that device's language and drops dead tokens.
 */
export async function deliver(eventId: string, d: Delivery): Promise<void> {
  const user = getFirestore().collection(paths.users).doc(d.to);
  if (d.record) {
    try {
      await user.collection(paths.notifications).doc(eventId).create({
        ...d.record,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if ((e as { code?: unknown }).code === alreadyExists) return;
      throw e;
    }
  }

  const devices = await user.collection(paths.devices).get();
  const byLang = new Map<Lang, string[]>();
  for (const doc of devices.docs) {
    const lang = langOf(doc.get("lang"));
    byLang.set(lang, [...(byLang.get(lang) ?? []), doc.id]);
  }

  const stale: string[] = [];
  for (const [lang, tokens] of byLang) {
    const res = await getMessaging().sendEachForMulticast(multicast(tokens, pushText(d.push, lang), d));
    res.responses.forEach((r, i) => {
      const code = r.error?.code;
      if (code && staleTokenErrors.has(code)) stale.push(tokens[i]);
      else if (code) logger.warn("push failed", { code, kind: d.push.kind });
    });
  }
  await Promise.all(stale.map((t) => user.collection(paths.devices).doc(t).delete()));
}
