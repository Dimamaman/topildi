# Shikoyat va bloklash: reja

## Hozirgi holat

- **Chatdagi shikoyat soxta.** `lib/features/chat/presentation/pages/chat_page.dart` dagi `_report` faqat tasdiq oynasini ko'rsatadi, keyin "Shikoyat yuborildi" chiqaradi. Hech narsa hech qayerga yuborilmaydi.
- **Eʼlon sahifasida shikoyat yo'q.** Boshqa odamning eʼlonida (`lib/features/listing/presentation/pages/detail_page.dart`) faqat "Ulashish" tugmasi bor.
- **Bloklash yo'q.**
- **App Store uchun majburiy.** Foydalanuvchilar kontent joylaydigan ilovalarda (Guideline 1.2) shikoyat, bloklash, moderatsiya va nomaqbul kontentga nol tolerantlik bandi bo'lishi shart.

## Qaror

Shikoyatlar moderatorga **Telegram bot orqali** yuboriladi. Bot allaqachon ishlab turibdi (`functions/src/telegram.ts`, `topildiTgWebhook`).

---

## 1-bosqich: haqiqiy shikoyat

### 1. Maʼlumotlar (Firestore)

Yangi kolleksiya: `topildi_reports/{targetType}_{targetId}_{reporterUid}`.
Id shunday tuzilgani uchun bitta odam bitta narsaga faqat bir marta shikoyat qila oladi, bu spamni to'xtatadi.

| Maydon | Turi | Izoh |
|---|---|---|
| `targetType` | `listing` \| `chat` | |
| `targetId` | string | eʼlon yoki chat id |
| `reportedUid` | string | shikoyat qilingan odam |
| `reporterId` | string | `request.auth.uid` |
| `reason` | `spam` \| `fake` \| `scam` \| `offensive` \| `other` | |
| `comment` | string, ≤300 | ixtiyoriy |
| `status` | `open` | moderator yopadi: `resolved` / `dismissed` |
| `createdAt` | timestamp | `== request.time` |

`firestore.rules`:
- Faqat yaratish mumkin. Ilova shikoyatlarni o'qimaydi, o'zgartirmaydi va o'chirmaydi.
- `reportedUid` tekshiriladi: eʼlon uchun u eʼlon muallifi, chat uchun suhbatdagi ikkinchi aʼzo bo'lishi kerak.
- O'z eʼloningizga shikoyat qilib bo'lmaydi. Chatga faqat uning aʼzosi shikoyat qila oladi.

### 2. Cloud Function: `topildiOnReportCreated`

Joyi: `functions/src/index.ts`. Mantiq alohida faylda bo'ladi, masalan `functions/src/report.ts`.

1. **Dalilni saqlash.** Shikoyat qilingan narsaning nusxasi hujjatga `evidence` maydoni sifatida yoziladi: eʼlon nomi, tavsifi va rasm URL'lari, chat uchun oxirgi ~20 xabar. Shunda u keyinroq o'chirilsa ham dalil qoladi.
2. **Telegramga yuborish.** Bot admin chatga xabar yuboradi: sabab, izoh, kim kimga shikoyat qildi, dalil qisqacha.
   - Yangi parametr: `TELEGRAM_ADMIN_CHAT_ID`. U `functions/.env` da `defineString` orqali saqlanadi.
3. **Avtomatik yashirish.** Eʼlonga 3 xil odam shikoyat qilsa, u `status: 'hidden'` bo'ladi.
   - `firestore.rules` dagi `validListing` / `status` ro'yxatlariga `hidden` qo'shiladi (uni faqat server qo'yadi).
   - Lenta, xarita va qidiruv `hidden` eʼlonlarni ko'rsatmaydi.

### 3. Ilova: `lib/features/report/`

Mavjud clean-architecture uslubida:

- `domain/entities/report.dart`: `ReportTarget`, `ReportReason`
- `domain/repositories/report_repository.dart`
- `domain/usecases/submit_report.dart`
- `data/datasources/firestore_report_datasource.dart` va mock datasource
- `data/repositories/report_repository_impl.dart`
- `presentation/widgets/report_sheet.dart`: glass sheet, sabab chiplari, ixtiyoriy izoh (≤300) va "Yuborish" tugmasi. Yuborish `TopildiLoader.run` orqali bo'ladi.
- Agar shikoyat avval yuborilgan bo'lsa (hujjat bor), "Shikoyatingiz allaqachon yuborilgan" ko'rsatiladi.

Kirish nuqtalari:
- **Chat:** mavjud `_report` shu sheet'ni ochadi.
- **Eʼlon (boshqa odamniki):** "Ulashish" o'rniga "Yana" menyusi bo'ladi: Ulashish va Shikoyat qilish.

---

## 2-bosqich: bloklash

**Maʼlumot:** `topildi_users/{uid}/blocked/{otherUid}`. Buni faqat egasi o'qiy va yoza oladi.

**Natija:**
- Bloklangan odamning eʼlonlari lentada va xaritada ko'rinmaydi (client tomonda filtrlanadi).
- U menga xabar ham, "Bu meniki" so'rovi ham yubora olmaydi. Buni `firestore.rules` tekshiradi: `!exists(/databases/$(database)/documents/topildi_users/$(otherUid)/blocked/$(request.auth.uid))`.
- Chatda yozish paneli o'rniga "Siz bu foydalanuvchini blokladingiz" banneri chiqadi, u yerda "Blokdan chiqarish" tugmasi bo'ladi.

**Kirish nuqtalari:**
- Chat menyusi: "Bloklash".
- Eʼlon menyusi ("Yana"): "Muallifni bloklash".
- Profil: "Bloklanganlar" ro'yxati, u yerdan blokdan chiqarish mumkin.

Usecase'lar: `BlockUser`, `UnblockUser`, `WatchBlocked`.

---

## 3-bosqich: tugatish

- **Moderator amallari:** Telegram xabarida inline tugmalar bo'ladi: "Eʼlonni yashirish", "Eʼlonni qaytarish", "Yopish". Ular mavjud `topildiTgWebhook` da `callback_query` orqali ishlaydi. Faqat `TELEGRAM_ADMIN_CHAT_ID` dan kelgan bosishlar qabul qilinadi.
- **Hisobni o'chirish** (`functions/src/account.ts`): foydalanuvchining o'zi yuborgan shikoyatlari va `blocked` ro'yxati ham o'chiriladi.
- **Foydalanish shartlari** (`lib/features/legal/domain/legal_documents.dart`): "nomaqbul kontent va suiisteʼmolga nol tolerantlik, shikoyatlar 24 soat ichida ko'rib chiqiladi" bandi qo'shiladi.
- **Tarjima:** yangi matnlar `lib/core/l10n/ru.dart` ga va kirill yozuviga qo'shiladi.
- **Testlar:**
  - `functions/src/test/report.test.ts`: Telegram xabar matni, dalil nusxasi, avtomatik yashirish chegarasi.
  - Cubit testlari: shikoyat yuborish, takroriy shikoyat, bloklash.

## Deploy (egasi qiladi)

1. `functions/.env` ga `TELEGRAM_ADMIN_CHAT_ID=...` qo'shiladi. Chat id'ni bilish uchun botga yozib, `getUpdates` dan olinadi.
2. Rules: `npx -y firebase-tools@15 deploy --only firestore:rules --project foodai-73d66`
3. Functions: `cd functions && npm run deploy`
4. Haqiqiy qurilmada tekshiriladi: chatdan shikoyat → Telegramga xabar keladi. Eʼlonga 3 ta shikoyat → eʼlon lentadan yo'qoladi. Bloklash → xabar yuborib bo'lmaydi.
