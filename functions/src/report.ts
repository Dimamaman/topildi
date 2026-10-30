/**
 * Shikoyatlar: what the moderator sees in Telegram, and when a listing is
 * hidden on its own. Pure functions (tested in src/test/report.test.ts);
 * Firestore and the Bot API live in moderate.ts.
 *
 * Document shape: topildi_reports/{targetType}_{targetId}_{reporterUid},
 * written by lib/features/report/data/datasources/firestore_report_datasource.dart
 * and locked down in firestore.rules (create only).
 */

export type ReportTargetType = "listing" | "chat";

export type ReportReason = "spam" | "fake" | "scam" | "offensive" | "other";

export type ReportDoc = {
  targetType: ReportTargetType;
  targetId: string;
  reportedUid: string;
  reporterId: string;
  reason: ReportReason;
  comment?: string;
};

/**
 * A copy of what was reported, kept on the report itself: the listing or the
 * last messages of the chat stay readable to the moderator after the author
 * deletes them.
 */
export type Evidence = {
  /** Listing title, or the chat's listing title. */
  title: string;
  /** One line per fact: description, place, or "Name: message". */
  lines: string[];
  photoUrls?: string[];
};

/** Distinct reporters that hide a listing from the feed, the map and search. */
export const hideThreshold = 3;

/** Chat messages copied as evidence (the newest ones). */
export const maxEvidenceMessages = 20;

/** Longest evidence line in the Telegram message. */
export const maxEvidenceLine = 200;

const reasonNames: Record<ReportReason, string> = {
  spam: "Spam",
  fake: "Soxta eʼlon",
  scam: "Firibgarlik",
  offensive: "Haqoratli",
  other: "Boshqa",
};

/** The app shows "Aldov" for a chat; the moderator reads the same word. */
export function reasonName(reason: ReportReason, targetType: ReportTargetType): string {
  if (reason === "fake" && targetType === "chat") return "Aldov";
  return reasonNames[reason] ?? reason;
}

/** Telegram HTML: only these three characters have to go. */
export function escapeHtml(text: string): string {
  return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function clip(text: string, max = maxEvidenceLine): string {
  const t = text.replace(/\s+/g, " ").trim();
  const chars = Array.from(t);
  return chars.length <= max ? t : chars.slice(0, max - 1).join("") + "…";
}

export type ReportNames = { reporter?: string; reported?: string };

/**
 * The message sent to the moderator chat. Plain facts, no interpretation:
 * who reported whom and why, then the evidence copied with the report.
 */
export function reportMessage(
  reportId: string,
  report: ReportDoc,
  evidence: Evidence | undefined,
  names: ReportNames = {},
  reports = 1,
): string {
  const e = escapeHtml;
  const target = report.targetType === "listing" ? "Eʼlon" : "Chat";
  const who = (name: string | undefined, uid: string) =>
    `${e(name?.trim() || "—")} <code>${e(uid)}</code>`;
  const lines = [
    `🚩 <b>Yangi shikoyat</b> · ${e(target)}`,
    "",
    `<b>Sabab:</b> ${e(reasonName(report.reason, report.targetType))}`,
  ];
  const comment = report.comment?.trim();
  if (comment) lines.push(`<b>Izoh:</b> ${e(clip(comment, 300))}`);
  lines.push(
    `<b>Kim:</b> ${who(names.reporter, report.reporterId)}`,
    `<b>Kimga:</b> ${who(names.reported, report.reportedUid)}`,
    `<b>Nishon:</b> <code>${e(report.targetId)}</code>`,
  );
  if (reports > 1) lines.push(`<b>Jami shikoyat:</b> ${reports}`);
  if (evidence) {
    lines.push("", `<b>${e(clip(evidence.title, 80) || "—")}</b>`);
    for (const l of evidence.lines.slice(0, maxEvidenceMessages)) {
      lines.push(e(clip(l)));
    }
    for (const url of (evidence.photoUrls ?? []).slice(0, 6)) {
      lines.push(`<a href="${e(url)}">rasm</a>`);
    }
  }
  lines.push("", `<code>${e(reportId)}</code>`);
  return lines.join("\n");
}

export type ModerationAction = "hide" | "restore" | "close";

/** callback_data, kept well under Telegram's 64 bytes by using the report id. */
export function callbackData(action: ModerationAction, reportId: string): string {
  return `r:${action}:${reportId}`;
}

export function parseCallbackData(data: unknown): { action: ModerationAction; reportId: string } | null {
  if (typeof data !== "string") return null;
  const m = /^r:(hide|restore|close):(.+)$/.exec(data);
  return m ? { action: m[1] as ModerationAction, reportId: m[2] } : null;
}

/** Buttons under the message; a chat report cannot be hidden, only closed. */
export function moderationKeyboard(reportId: string, targetType: ReportTargetType) {
  const button = (text: string, action: ModerationAction) => ({
    text,
    callback_data: callbackData(action, reportId),
  });
  const rows =
    targetType === "listing"
      ? [[button("🙈 Eʼlonni yashirish", "hide"), button("↩️ Qaytarish", "restore")]]
      : [];
  return { inline_keyboard: [...rows, [button("✅ Yopish", "close")]] };
}

/** What the moderator sees once a button has been pressed. */
export function moderationNote(action: ModerationAction): string {
  return {
    hide: "🙈 Eʼlon yashirildi",
    restore: "↩️ Eʼlon qaytarildi",
    close: "✅ Yopildi",
  }[action];
}

/** The report's new status after [action]; "close" leaves it resolved. */
export function statusAfter(action: ModerationAction): "resolved" | "dismissed" {
  return action === "restore" ? "dismissed" : "resolved";
}
