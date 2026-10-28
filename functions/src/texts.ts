/**
 * Push texts in the three interface languages. They match the app's
 * notification texts (lib/features/notifications/.../notifications_page.dart
 * and lib/core/l10n/ru.dart); the Cyrillic Uzbek is written out here because
 * the app's Latin → Cyrillic converter lives in Dart.
 */

export type Lang = "uz_Latn" | "uz_Cyrl" | "ru";

export const langs: readonly Lang[] = ["uz_Latn", "uz_Cyrl", "ru"];

/** Unknown or missing → Uzbek Latin, the app's default. */
export function langOf(code: unknown): Lang {
  return langs.includes(code as Lang) ? (code as Lang) : "uz_Latn";
}

export type PushText = { title: string; body: string };

/** What a push says, before it is put into a language. */
export type PushContent =
  | { kind: "newClaim"; listingTitle: string }
  | { kind: "claimAccepted"; actorName: string }
  | { kind: "claimRejected"; listingTitle: string; attemptsLeft: number }
  | { kind: "returned"; actorName: string }
  | { kind: "message"; actorName: string; text: string }
  | { kind: "reminder"; count: number; listingTitle?: string };

/** Longest chat message shown in a push. */
export const maxMessage = 80;

export function shorten(text: string, max = maxMessage): string {
  const t = text.replace(/\s+/g, " ").trim();
  const chars = Array.from(t); // keep emoji whole
  return chars.length <= max ? t : chars.slice(0, max - 1).join("").trimEnd() + "…";
}

export function pushText(c: PushContent, lang: Lang): PushText {
  switch (c.kind) {
    case "newClaim":
      return {
        uz_Latn: { title: "Yangi soʻrov", body: `“${c.listingTitle}” eʼloningizga yangi soʻrov keldi. Javobni tekshiring.` },
        uz_Cyrl: { title: "Янги сўров", body: `“${c.listingTitle}” эълонингизга янги сўров келди. Жавобни текширинг.` },
        ru: { title: "Новая заявка", body: `Новая заявка по объявлению «${c.listingTitle}». Проверьте ответ.` },
      }[lang];
    case "claimAccepted":
      return {
        uz_Latn: { title: "Soʻrov qabul qilindi", body: `${c.actorName} soʻrovingizni qabul qildi. Chatda kelishib oling.` },
        uz_Cyrl: { title: "Сўров қабул қилинди", body: `${c.actorName} сўровингизни қабул қилди. Чатда келишиб олинг.` },
        ru: { title: "Заявка принята", body: `${c.actorName} принял(а) вашу заявку. Договоритесь в чате.` },
      }[lang];
    case "claimRejected": {
      const n = c.attemptsLeft;
      const t = c.listingTitle;
      return {
        uz_Latn: {
          title: "Soʻrov rad etildi",
          body: n > 0
            ? `“${t}” boʻyicha soʻrovingiz rad etildi. Yana ${n} ta urinishingiz bor.`
            : `“${t}” boʻyicha soʻrovingiz rad etildi.`,
        },
        uz_Cyrl: {
          title: "Сўров рад этилди",
          body: n > 0
            ? `“${t}” бўйича сўровингиз рад этилди. Яна ${n} та уринишингиз бор.`
            : `“${t}” бўйича сўровингиз рад этилди.`,
        },
        ru: {
          title: "Заявка отклонена",
          body: n > 0
            ? `Ваша заявка по «${t}» отклонена. Осталось попыток: ${n}.`
            : `Ваша заявка по «${t}» отклонена.`,
        },
      }[lang];
    }
    case "returned":
      return {
        uz_Latn: { title: "Buyumingiz qaytdi!", body: `${c.actorName} buyumingizni qaytardi. Unga rahmat aytishni unutmang!` },
        uz_Cyrl: { title: "Буюмингиз қайтди!", body: `${c.actorName} буюмингизни қайтарди. Унга раҳмат айтишни унутманг!` },
        ru: { title: "Ваша вещь вернулась!", body: `${c.actorName} вернул(а) вашу вещь. Не забудьте поблагодарить!` },
      }[lang];
    case "reminder": {
      const n = c.count;
      const t = c.listingTitle;
      return {
        uz_Latn: {
          title: n > 1 ? `Sizni ${n} ta soʻrov kutyapti` : "Sizni soʻrov kutyapti",
          body: t
            ? `“${t}” eʼloningizga kelgan soʻrovga hali javob bermadingiz. Javobni tekshiring.`
            : "Eʼlonlaringizga kelgan soʻrovlarga hali javob bermadingiz. Javobni tekshiring.",
        },
        uz_Cyrl: {
          title: n > 1 ? `Сизни ${n} та сўров кутяпти` : "Сизни сўров кутяпти",
          body: t
            ? `“${t}” эълонингизга келган сўровга ҳали жавоб бермадингиз. Жавобни текширинг.`
            : "Эълонларингизга келган сўровларга ҳали жавоб бермадингиз. Жавобни текширинг.",
        },
        ru: {
          title: n > 1 ? `Вас ждут заявки: ${n}` : "Вас ждёт заявка",
          body: t
            ? `Вы ещё не ответили на заявку по «${t}». Проверьте ответ.`
            : "Вы ещё не ответили на заявки по вашим объявлениям. Проверьте ответы.",
        },
      }[lang];
    }
    case "message":
      // Same in every language: who wrote, and what.
      return { title: c.actorName, body: shorten(c.text) };
  }
}
