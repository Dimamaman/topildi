import type { MulticastMessage } from "firebase-admin/messaging";
import type { Delivery } from "./events";
import type { PushText } from "./texts";

/**
 * One FCM multicast for the recipient's devices that share a language,
 * addressed by FCM registration token (lib/core/push/push_service.dart):
 * sends to FIDs fail while the app's FID registration fails on iOS.
 */
export function multicast(tokens: string[], text: PushText, d: Delivery): MulticastMessage {
  return {
    tokens,
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

/** FCM errors that mean the token is gone for good: its device doc is deleted. */
export const staleTokenErrors: ReadonlySet<string> = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);
