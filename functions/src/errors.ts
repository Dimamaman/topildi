/**
 * Xatoliklar: what the developer chat sees when the app runs into an error.
 * Pure functions here (tested in src/test/errors.test.ts); the Bot API call
 * and the daily cap live in index.ts.
 *
 * The app sends these through the `topildiLogError` callable
 * (lib/core/error/error_reporter.dart) — never straight to Telegram, so the
 * bot token stays out of the app.
 */
import { escapeHtml } from "./report";

/** Where the error was caught in the app. */
export type ErrorKind = "flutter" | "platform" | "zone" | "manual";

export type ErrorReport = {
  kind: ErrorKind;
  /** First line: the exception itself. */
  message: string;
  stack?: string;
  /** The page the person was on, e.g. "/listing/l3". */
  route?: string;
  /** What the app was doing, when it knows: "Shikoyat yuborish". */
  action?: string;
  uid?: string;
  /** "1.0.0+2" */
  appVersion?: string;
  /** "iOS 18.2" */
  platform?: string;
  /** "iPhone14,2" */
  device?: string;
  /** Interface language: "uzLatn" / "ru". */
  language?: string;
  /** False for a debug or profile build. */
  release?: boolean;
  /** The device's clock when it happened (ISO). */
  at?: string;
};

/** Stack frames kept; the rest is Flutter's own plumbing anyway. */
export const maxStackLines = 14;

/** Longest single field (message, route, action…) in the message. */
export const maxFieldChars = 400;

/** Telegram's own limit is 4096; this leaves room for the markup. */
export const maxMessageChars = 3500;

/** Errors sent to the chat in one day, after which the rest are dropped. */
export const maxErrorsPerDay = 200;

const kinds: ErrorKind[] = ["flutter", "platform", "zone", "manual"];

const text = (v: unknown, max = maxFieldChars): string | undefined => {
  if (typeof v !== "string") return undefined;
  const t = v.trim();
  if (!t) return undefined;
  const chars = Array.from(t);
  return chars.length <= max ? t : chars.slice(0, max - 1).join("") + "…";
};

/**
 * What the callable accepts. Anything missing is simply left out of the
 * message — a half-filled report is still better than none.
 */
export function parseErrorReport(data: unknown, uid?: string): ErrorReport | null {
  const d = (data ?? {}) as Record<string, unknown>;
  const message = text(d.message);
  if (!message) return null;
  const kind = kinds.find((k) => k === d.kind) ?? "manual";
  const stack = text(d.stack, 4000);
  return {
    kind,
    message,
    stack: stack ? trimStack(stack) : undefined,
    route: text(d.route),
    action: text(d.action),
    uid: text(d.uid) ?? uid,
    appVersion: text(d.appVersion, 40),
    platform: text(d.platform, 60),
    device: text(d.device, 60),
    language: text(d.language, 20),
    release: typeof d.release === "boolean" ? d.release : undefined,
    at: text(d.at, 40),
  };
}

/** The top of the stack, without the frames every error shares. */
export function trimStack(stack: string): string {
  const lines = stack
    .split("\n")
    .map((l) => l.trimEnd())
    .filter((l) => l.trim().length > 0);
  const kept = lines.slice(0, maxStackLines);
  if (lines.length > kept.length) kept.push(`… +${lines.length - kept.length}`);
  return kept.join("\n");
}

/** One day's key for the counter that caps how much the chat hears. */
export function errorRateDay(now: Date = new Date()): string {
  return now.toISOString().slice(0, 10);
}

/**
 * The message the developer chat gets: where it happened first, then what
 * happened, then the stack. Everything is escaped — an error text can carry
 * anything the user typed.
 */
export function errorMessage(r: ErrorReport): string {
  const e = escapeHtml;
  const head = [r.platform, r.appVersion && `v${r.appVersion}`, r.release === false && "debug"]
    .filter(Boolean)
    .join(" · ");
  const lines = [`🐞 <b>Xatolik</b>${head ? ` · ${e(head)}` : ""}`, ""];
  if (r.route) lines.push(`<b>Sahifa:</b> <code>${e(r.route)}</code>`);
  if (r.action) lines.push(`<b>Amal:</b> ${e(r.action)}`);
  lines.push(`<b>Xabar:</b> ${e(r.message)}`);
  const where = [`tur: ${r.kind}`, r.device && `qurilma: ${r.device}`, r.language && `til: ${r.language}`]
    .filter(Boolean)
    .join(" · ");
  lines.push(`<b>Qayerda:</b> ${e(where)}`);
  if (r.uid) lines.push(`<b>Kim:</b> <code>${e(r.uid)}</code>`);
  if (r.at) lines.push(`<b>Vaqt:</b> ${e(r.at)}`);
  if (r.stack) lines.push("", `<pre>${e(r.stack)}</pre>`);
  const message = lines.join("\n");
  if (message.length <= maxMessageChars) return message;
  return message.slice(0, maxMessageChars - 10) + "…</pre>";
}
