import type { FidMulticastMessage } from "firebase-admin/messaging";
import type { Delivery } from "./events";
import type { PushText } from "./texts";

/**
 * One FCM multicast for the recipient's devices that share a language.
 * Devices are addressed by Firebase Installation ID (FID), which the app
 * gets from `FirebaseMessaging.register()`.
 */
export function multicast(fids: string[], text: PushText, d: Delivery): FidMulticastMessage {
  return {
    fids,
    notification: { title: text.title, body: text.body },
    // Read by lib/core/push/push_service.dart when the push is tapped.
    data: { route: d.route },
    apns: {
      payload: {
        aps: { sound: "default", ...(d.threadId ? { threadId: d.threadId } : {}) },
      },
    },
  };
}

/** FCM errors that mean the FID is gone for good: its device doc is deleted. */
export const staleTokenErrors: ReadonlySet<string> = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);
