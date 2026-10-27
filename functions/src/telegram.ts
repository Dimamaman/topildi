/**
 * Phone sign-in through the Telegram bot. Pure functions (tested in
 * src/test/) for reading bot updates, checking a shared contact and the
 * bot's replies; Firestore and Auth live in login.ts.
 *
 * Flow: the app opens t.me/<bot>?start=<sid>, the bot asks for the contact,
 * the person shares their own number, the app claims a custom token.
 */

/** Session lifetime, from creation until the app claims it. */
export const sessionTtlMs = 10 * 60 * 1000;

/** The parts of a Telegram Update the bot reads. */
export type TgUpdate = {
  message?: {
    chat?: { id?: number };
    from?: { id?: number; first_name?: string; language_code?: string };
    text?: string;
    contact?: { phone_number?: string; user_id?: number; first_name?: string };
  };
};

export type Incoming =
  | { kind: "start"; chatId: number; sid: string; lang: BotLang }
  | {
      kind: "contact";
      chatId: number;
      fromId: number;
      contactUserId?: number;
      phone: string;
      /** The account's Telegram first name, for the Topildi profile. */
      name: string;
      lang: BotLang;
    }
  | { kind: "other"; chatId: number; lang: BotLang };

/** Session ids we hand out: base64url, also valid as a /start payload. */
const sidPattern = /^[A-Za-z0-9_-]{16,64}$/;

export function parseUpdate(update: TgUpdate): Incoming | null {
  const m = update.message;
  const chatId = m?.chat?.id;
  if (!m || typeof chatId !== "number") return null;
  const lang = botLang(m.from?.language_code);
  if (m.contact) {
    const fromId = m.from?.id;
    if (typeof fromId !== "number") return null;
    return {
      kind: "contact",
      chatId,
      fromId,
      contactUserId: m.contact.user_id,
      phone: m.contact.phone_number ?? "",
      name: cleanName(m.from?.first_name ?? m.contact.first_name ?? ""),
      lang,
    };
  }
  // "/start <sid>" from the deep link, or the link itself pasted into the
  // bot's chat (handy when Telegram is on another device than the app).
  const text = m.text?.trim() ?? "";
  const start = /^\/start(?:@\w+)?\s+(\S+)$/.exec(text) ?? /^https?:\/\/t\.me\/\w+\?start=(\S+)$/.exec(text);
  if (start && sidPattern.test(start[1])) return { kind: "start", chatId, sid: start[1], lang };
  return { kind: "other", chatId, lang };
}

/** "+998 90 123-45-67", "998901234567" → "+998901234567"; anything else → null. */
export function normalizePhone(raw: string): string | null {
  const d = raw.replace(/\D/g, "");
  return /^998\d{9}$/.test(d) ? `+${d}` : null;
}

/** Same limit as topildi_users.firstName in firestore.rules. */
export const maxNameLength = 30;

/** When the Telegram name has nothing printable left. */
export const fallbackName = "Foydalanuvchi";

/**
 * Telegram first name → profile name: control and invisible characters
 * removed (except the joiner inside emoji like 👨‍👩‍👧), spaces collapsed, at most [maxNameLength] characters (never
 * splitting an emoji's surrogate pair).
 */
export function cleanName(raw: string): string {
  const name = raw
    .replace(/[\p{Cc}\p{Cf}]/gu, (c) => (c === "\u200d" ? c : ""))
    .replace(/\s+/gu, " ")
    .trim();
  const short = Array.from(name).slice(0, maxNameLength).join("").trim();
  return short || fallbackName;
}

export type ContactCheck = { ok: true; phone: string } | { ok: false; reason: "foreign" | "badPhone" };

/**
 * Only the sender's own number counts: a forwarded or typed-in contact has
 * another (or no) user_id, and would let anyone sign in as that number.
 */
export function checkContact(c: { fromId: number; contactUserId?: number; phone: string }): ContactCheck {
  if (c.contactUserId !== c.fromId) return { ok: false, reason: "foreign" };
  const phone = normalizePhone(c.phone);
  return phone ? { ok: true, phone } : { ok: false, reason: "badPhone" };
}

/** Stored in topildi_tg_sessions/{sid}; never readable by clients. */
export type Session = {
  secretHash: string;
  status: "pending" | "verified";
  expiresAt: number;
  phone?: string;
  /** Telegram first name, set with the phone. */
  name?: string;
};

export type SessionState = "missing" | "expired" | "pending" | "verified";

export function sessionState(s: Partial<Session> | undefined, now: number): SessionState {
  if (!s || typeof s.expiresAt !== "number") return "missing";
  if (s.expiresAt <= now) return "expired";
  return s.status === "verified" && typeof s.phone === "string" ? "verified" : "pending";
}

export type BotLang = "uz" | "ru";

export function botLang(code: unknown): BotLang {
  return typeof code === "string" && code.startsWith("ru") ? "ru" : "uz";
}

export type BotText = "askContact" | "shareButton" | "verified" | "foreign" | "badPhone" | "expired" | "openApp";

const texts: Record<BotLang, Record<BotText, string>> = {
  uz: {
    askContact: "Topildi ilovasiga kirish uchun pastdagi tugmani bosib, raqamingizni ulashing.",
    shareButton: "📱 Raqamni ulashish",
    verified: "✅ Raqamingiz tasdiqlandi. Endi Topildi ilovasiga qayting.",
    foreign: "Faqat oʻz raqamingizni ulashing: pastdagi tugmani bosing.",
    badPhone: "Hozircha faqat Oʻzbekiston raqamlari (+998) qabul qilinadi.",
    expired: "Bu havolaning muddati tugagan. Ilovada «Telegram orqali kirish»ni qayta bosing.",
    openApp: "Kirish uchun Topildi ilovasida «Telegram orqali kirish» tugmasini bosing.",
  },
  ru: {
    askContact: "Чтобы войти в Topildi, нажмите кнопку ниже и поделитесь своим номером.",
    shareButton: "📱 Поделиться номером",
    verified: "✅ Номер подтверждён. Вернитесь в приложение Topildi.",
    foreign: "Поделитесь своим номером: нажмите кнопку ниже.",
    badPhone: "Пока принимаются только номера Узбекистана (+998).",
    expired: "Срок действия ссылки истёк. Нажмите «Войти через Telegram» в приложении ещё раз.",
    openApp: "Чтобы войти, нажмите «Войти через Telegram» в приложении Topildi.",
  },
};

export const botText = (lang: BotLang, t: BotText): string => texts[lang][t];

/**
 * The reply, as a Bot API call returned in the webhook response, so the
 * function needs no bot token. [askContact] shows the share-number button;
 * otherwise the keyboard is removed.
 */
export function reply(chatId: number, lang: BotLang, t: BotText, askContact = false) {
  return {
    method: "sendMessage",
    chat_id: chatId,
    text: botText(lang, t),
    reply_markup: askContact
      ? {
          keyboard: [[{ text: botText(lang, "shareButton"), request_contact: true }]],
          resize_keyboard: true,
          one_time_keyboard: true,
        }
      : { remove_keyboard: true },
  };
}
