# Topildi — loyiha holati

> Oxirgi yangilanish: 2026-10-26

Topildi — yo'qolgan va topilgan buyumlar uchun Flutter ilova.
- **Arxitektura**: Clean Architecture — `flutter_bloc`, `get_it` + `injectable` (`@prod` / `@test`), `fpdart`.
- **Interfeys**: o'zbek tilida (lotin), kirill va rus tillari ham bor.
- **Backend**: Firebase (`foodai-73d66`, Blaze). **Platforma: hozircha faqat iOS.**

## Qisqacha

| Bo'lim | Holat |
|---|---|
| Dizayn (iOS 26 glass uslubi) | ✅ tayyor |
| Lokalizatsiya (uz-Latn, uz-Cyrl, ru) | ✅ tayyor |
| Firebase 1-bosqich: kirish, profil, lenta, eʼlon | ✅ tayyor, simulatorda kirish va eʼlon joylash ishladi |
| Firebase 2-bosqich: so'rovlar ("Bu meniki" / "Men topdim") va chat | ✅ kod va rules deploy qilingan, ikki akkaunt bilan to'liq sinov qolgan |
| Push bildirishnomalar | 🟡 kod tayyor (`push-notifications` branch), emulatorda sinalgan; APNs kalit, Xcode va deploy qoldi |
| Bildirishnomalar sahifasi | 🟡 Firestore'dan o'qiydi; Cloud Functions deploy qilingach to'ladi |
| Xarita | ⏸ `Features.map` bilan yashirilgan |
| Android | ⏳ sozlanmagan |

**Branchlar (2026-10-26):** hamma ish `main` ga birlashtirildi — PR #3 → `firebase-phase1` → `main` (fast-forward). Yangi ish `main` dan alohida branch'da boshlanadi.

**Tekshiruv:** `flutter analyze` toza; `flutter test` — 88 ta test o'tadi; `functions`: `npm test` — 13 ta; `flutter build ios --simulator --debug` muvaffaqiyatli; Firestore va Storage rules deploy qilingan.

---

## ✅ Qilingan ishlar

### 1. Dizayn (iOS 26 uslubi)

**Glass UI tizimi:** `GlassSurface` (blur, saturatsiya, chekka yorug'ligi, soya), `TGlass` tokenlari, glass header va sheet, `OverlayEntry` asosidagi pull-down menyu (bosib-sudrab tanlash).

**Ekranlar:** Kirish, SMS kod, Tanishib olaylik (orbita avatar, emoji, rang), Lenta (2 ustunli grid, skeleton, tur tablari, bo'sh holatda glass ikonka + "+" ga strelka), Mening eʼlonlarim, Filtrlar sheeti, Hudud menyusi, Bildirishnomalar, Chatlar, Chat, Profil, barcha dialoglar (glass alert).

### 2. Lokalizatsiya

- Matnlar `tr('...')` ga o'raladi, kalit — o'zbekcha (lotin) matnning o'zi.
- Kirill lotindan avtomatik o'giriladi (`toUzbekCyrillic`); ruscha — `lib/core/l10n/ru.dart`.
- Til **Til** menyusida almashadi, ilova darhol qayta chiziladi (`LanguageCubit`); sanalar tilga mos.
- `test/core/l10n_test.dart` har bir `tr()` matnining ruscha tarjimasi borligini tekshiradi.

### 3. Firebase 1-bosqich — kirish, profil, lenta, eʼlon

Loyiha **FoodZeen** ilovasi bilan umumiy, shuning uchun Topildi'ning hamma narsasi alohida nom ostida (`FirePaths`, `lib/core/di/firebase_module.dart`).

| Qism | Fayllar |
|---|---|
| Ulash | `lib/firebase_options.dart`, `ios/Runner/GoogleService-Info.plist`, `main.dart` da `Firebase.initializeApp` |
| iOS | deployment target 15.0, Google URL scheme'lar, Podfile'da oldindan kompilyatsiya qilingan Firestore (build ~1 daqiqa); `SceneDelegate.swift` reCAPTCHA URL'ini `Auth.auth().canHandle` ga uzatadi, `FlutterDeepLinkingEnabled = false` |
| DI | `firebase_module.dart` — `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `GoogleSignIn` (`@prod`) |
| Auth | `firebase_auth_repository.dart` — SMS kod (`+998…`) va Google; profil `topildi_users/{uid}` |
| Session | `session.dart` — `FirebaseSession` (`@prod`), `LocalSession` (`@test`) |
| Eʼlonlar | `listing_remote_datasource.dart` (interfeys), `firestore_listing_datasource.dart` (`@prod`), `listing_mock_datasource.dart` (`@test`), `listing_firestore.dart` |
| Rasmlar | `photo_compress.dart` — 1600px, sifat 82, EXIF o'chiriladi |
| Xatolar | `firebase_failure.dart` (`failureOf`) — `FirebaseException` → `Failure`; xatolar logga chiqadi |

**Konsolda qilingan:** Phone provider yoqilgan, test raqam `+998 90 660 13 14` → `123456`; SMS region policy'da O'zbekiston ruxsat etilgan.

### 4. Firebase 2-bosqich — so'rovlar va chat

Cloud Functions yo'q: chatni ilova yaratadi, xavfsizlikni Firestore rules taʼminlaydi.

**Oqim:**
1. **Topilgan eʼlon:** topgan odam eʼlon beradi va faqat egasi biladigan yashirin belgini yozadi → egasi **"Bu meniki"** bosib, belgini yozadi (ixtiyoriy dalil rasm bilan).
2. **Yo'qolgan eʼlon:** egasi eʼlon beradi va yashirin belgini yozadi → topgan odam **"Men topdim"** bosib, buyumdagi belgini yozadi.
3. Eʼlon muallifi so'rovlarni ko'radi (yashirin belgi yonida javob), qabul yoki rad qiladi. Har bir odamga 3 ta urinish; yangisi faqat oldingisi rad etilgandan keyin.
4. Qabul qilinsa chat ochiladi: xabarlar real vaqtda, o'qilmagan soni Chatlar tab'ida, o'z xabarida ✓ / ✓✓ (o'qildi).
5. Topgan odam **"Qaytarildi"** bosadi → chat yopiladi, eʼlon `returned` bo'ladi, topgan odamga +1 qaytarilgan buyum, Success ekrani.
6. Kutayotgan so'rovlar soni **Profil** tab'ida qizil belgi bilan, real vaqtda; profildagi "Soʻrov bor · N" teglari o'zi yangilanadi.

**Firestore modeli:**
- `topildi_claims/{listingId}_{uid}_{n}` — n = 1..3 urinish. Javob va dalil rasmni faqat so'rovchi va eʼlon muallifi o'qiydi. Dalil rasm: Storage `topildi/claims/{id}/proof.jpg`.
- `topildi_chats/{claimId}` — muallif qabul qilganda claim bilan bitta batch'da yaratiladi. `members`, `finderId` (topilgan → muallif, yo'qolgan → so'rovchi), `unread.{uid}`, `readAt.{uid}`, `returned`.
- `topildi_chats/{id}/messages/{mid}` — `text` yoki `returned`. "Mos keldi" va xavfsizlik eslatmasi saqlanmaydi, chat `createdAt` dan chiziladi.
- Yo'qolgan eʼlonda topgan odam muallif emas — u eʼlonni `returnedViaChat` orqali yopadi (rules chat'dagi `finderId` ni tekshiradi).

| Qism | Fayllar |
|---|---|
| So'rovlar | `claim_remote_datasource.dart`, `firestore_claim_datasource.dart` (`@prod`), `claim_mock_datasource.dart` (`@test`), `claim_firestore.dart` |
| Chat | `chat_remote_datasource.dart` (+ `ChatNotes`), `firestore_chat_datasource.dart` (`@prod`), `chat_mock_datasource.dart` (`@test`), `chat_firestore.dart` |
| Real vaqt | `ChatListCubit`, `ChatCubit` (`WatchChats`, `WatchChat`, `MarkChatRead`), `PendingClaimsCubit` (`WatchPendingClaims`) |
| UI | "Men topdim" → so'rov formasi (topgan odam matnlari), `ClaimSentArgs`, Profil tab belgisi (`TBottomNav.pendingClaims`) |
| Rules | `firestore.rules` (claims, chats, messages, chat orqali eʼlonni yopish), `storage.rules` (dalil rasm), `firestore.indexes.json` (chats: `members` + `lastAt`) |
| Testlar | `claim_firestore_test`, `chat_firestore_test`, `claim_flow_test` ("Men topdim", Profil belgisi) |

**Deploy qilingan (2026-10-26):** `firebase deploy --only firestore,storage --project foodai-73d66` — rules va indekslar.

### 5. Tuzatishlar

- **Shell layout xatosi** ("_RenderLayoutBuilder was mutated in RenderViewport.performLayout", "Each child must be laid out exactly once"): shell cubit'lari endi `lazy: false` — birinchi o'quvchi Lenta'ning qotib turuvchi sarlavhasi edi, u layout paytida quriladi.
- Xarita `Features.map` bilan yashirildi (pastda).

### 6. Push bildirishnomalar va Bildirishnomalar sahifasi (`push-notifications` branch)

| Hodisa | Kimga | Push bosilsa | Sahifada |
|---|---|---|---|
| Yangi so'rov | eʼlon muallifi | Soʻrovlar | ✅ |
| So'rov qabul qilindi | so'rovchi | Chat | ✅ |
| So'rov rad etildi (qolgan urinishlar bilan) | so'rovchi | Eʼlon | ✅ |
| Chat xabari | ikkinchi aʼzo | Chat | ❌ (Chatlar tabi bor) |
| "Qaytarildi" | buyum egasi | Success | ✅ |

- **Cloud Functions** — `functions/` (TypeScript, Node 22), `firebase.json` da alohida **`topildi` codebase**: `firebase deploy --only functions:topildi` FoodZeen funksiyalariga tegmaydi. Nomlar `topildi` bilan boshlanadi. Triggerlar: `topildiOnClaimCreated`, `topildiOnClaimUpdated`, `topildiOnMessageCreated`.
  - `events.ts` — kimga nima (sof funksiyalar), `texts.ts` — push matnlari 3 tilda, `payload.ts` — FCM xabari, `notify.ts` — yozish va yuborish.
  - Bildirishnoma hujjati id'si = trigger event id: qayta urinishda ikki marta yozilmaydi va push takrorlanmaydi. O'lik qurilmalar (`UNREGISTERED`) o'chiriladi.
  - Region: `index.ts` dagi `region` (hozir `us-central1`) **Firestore joylashuvi bilan bir xil bo'lishi kerak** — deploy oldidan konsolda tekshiring.
- **Firestore:** `topildi_users/{uid}/devices/{fid}` — `{fid, platform, lang, updatedAt}`, faqat egasi; `topildi_users/{uid}/notifications/{id}` — `{kind, listingId, listingTitle, chatId?, actorName?, attemptsLeft?, read, createdAt}`, faqat Functions yozadi, egasi faqat `read` ni o'zgartiradi. Matn saqlanmaydi — ilova uni tilga qarab chizadi.
- **Ilova:** `lib/core/push/push_service.dart` (`FirebasePushService` `@prod`, `NoopPushService` `@test`) — `firebase_messaging` 17 ning FID API'si (`register()` / `onRegistered`). Shell ochilganda boshlanadi, push bosilsa `data.route` ochiladi (ilova yopiq bo'lsa ham). Profil'dagi "Bildirishnomalar" kaliti yoqadi/o'chiradi; chiqishdan oldin qurilma o'chiriladi. Chat ekrani ochiq turganda bannerlar o'chiriladi. Til almashsa push tili ham almashadi.
- **Sahifa:** `firestore_notification_datasource.dart` (oxirgi 50 ta, o'qilmaganlar soni real vaqtda), `notification_firestore.dart`.
- **Testlar:** `functions/src/test/events.test.ts` (13 ta, `npm test`), `notification_firestore_test`, `push_settings_test`. Emulatorda to'liq tekshirilgan: 4 trigger to'g'ri hujjat yozadi, matnli xabar sahifaga tushmaydi, rules begonaga o'qitmaydi.

### Maxfiylik qoidalari (saqlanadi)

- **Telefon raqami** Firestore'ga hech qachon yozilmaydi — na eʼlonda, na so'rovda, na chatda.
- **Koordinatalar** yozishdan oldin ~300 m aniqlikkacha yaxlitlanadi.
- **Yashirin belgi** faqat `topildi_listings/{id}/private/secret` da, uni faqat muallif o'qiydi.
- **Rasmlar** (eʼlon, avatar, dalil) EXIF/GPS'siz yuklanadi.
- **Chat** faqat so'rov qabul qilingandan keyin ochiladi va faqat ikki aʼzoga ko'rinadi.

---

## ⏳ Qilinishi kerak

### 1. Sinov (eng avval)

1. Firebase konsolida `topildi_chats` indeksi **Enabled** bo'lganini tekshirish.
2. Konsolga ikkinchi test raqam qo'shish (Authentication → Phone → test numbers).
3. Simulatorda ikki akkaunt bilan:
   - Topilgan eʼlon → "Bu meniki" (dalil rasm bilan) → Profil'da qizil belgi → qabul → chat, real vaqtda xabar, Chatlar belgisi, ✓✓ → "Qaytarildi" → Success.
   - Yo'qolgan eʼlon → "Men topdim" → qabul → chat → "Qaytarildi" (topgan odam bosadi, eʼlon yopiladi).
   - Rad etish va 3 urinish chegarasi.
4. Konsolda: claim/chat hujjatlarida telefon yo'q; Storage'dagi dalil rasmlar EXIF'siz.
5. 1-bosqichdan qolgan sinovlar: profil saqlash, filtrlar, o'chirish, chiqish.

### 2. Push bildirishnomalarni ishga tushirish

1. **Egasi qiladi:** Apple Developer → Keys → APNs `.p8` kalit → Firebase → Project settings → Cloud Messaging → Topildi iOS ilovasiga yuklash.
2. **Egasi qiladi:** Xcode → Runner → Signing & Capabilities → **Push Notifications** (Background Modes → Remote notifications allaqachon yoqilgan).
3. `functions/src/index.ts` dagi `region` ni Firestore joylashuviga moslash.
4. Deploy: `cd functions && npm ci && cd .. && firebase deploy --only functions:topildi,firestore:rules --project foodai-73d66`.
5. Haqiqiy iPhone'da ikki akkaunt bilan sinov (simulatorda push to'liq ishlamaydi): har bir hodisa, push bosilganda to'g'ri ekran (ilova yopiq / fonda / ochiq), chiqqandan keyin push kelmasligi, til almashganda push tili.
6. Keyin: ilova ikonkasidagi badge soni (hozir yuborilmaydi), o'xshash eʼlon topilganda bildirishnoma.

### 3. Bildirishnomalar sahifasi

Firestore'ga ulangan (yuqorida). Hozircha "o'xshash buyum topildi" va "eʼlon arxivlanadi" turlari yo'q.

### 4. Mayda kamchiliklar

- SMS kod xato matnlari dizayn bilan bir xil emas: Firebase "Kod notoʻgʻri. Qayta tekshiring" / "Kod eskirdi. Yangisini oling", dizayn — "Qayta kiriting" / "Kod eskirgan. Yangisini soʻrang"; kod eskirganda "Qayta yuborish" darhol faollashishi kerak.
- Eʼlonni tahrirlash oqimi yo'q ("tez orada" toast).
- Eʼlon sahifasidagi muallif uchun so'rovlar soni sahifa ochilganda yuklanadi (real vaqtda emas).
- Simulator uchun reCAPTCHA'ni o'chirish (`appVerificationDisabledForTesting`, faqat test raqamlar bilan) — taklif qilingan, qilinmagan.

### 5. Keyinroq

- **Android:** `google-services.json`, Gradle plagini, SHA-1/SHA-256, `firebase_options.dart` ga Android.
- **Chat:** telefon yoki karta raqami yozilsa ogohlantirish; xabarga rasm.
- **Xarita:** `Features.map` ni yoqish — `flutter run --dart-define=FEATURE_MAP=true` yoki `lib/core/config/features.dart` da standart qiymat `true`. Yashirin holatda: Xarita tabi va eʼlondagi "Xaritada" qatori ko'rinmaydi, eʼlon joylashda xarita o'rniga "Joylashuvim" va "Tumanni tanlash".
- **Telegram Gateway** orqali SMS kod — muhokama qilingan, hozircha faqat Firebase SMS.

---

## Ish uslubi

- Foydalanuvchi bilan o'zbekcha gaplashiladi.
- Dizayn topshiriqlari PDF + PNG (+ HTML) bilan keladi; har bir ekran real Inter va Material Symbols shriftlari bilan golden skrinshot qilinib dizayn bilan solishtiriladi (393, 375×667, 360; yorug'/qorong'i; 130% matn).
- Matnlar `tr()` orqali, yangi matnga `ru.dart` da tarjima shart (`l10n_test`).
- Ripple yo'q, bosiladigan joy ≥44.
- Yangi data manbalari: interfeys + `@prod` Firestore + `@test` mock (testlar Firebase'ga tegmaydi).
- Rules o'zgarganda: avval `firebase deploy --only firestore,storage --project foodai-73d66 --dry-run`, deploy faqat ruxsat bilan. FoodZeen qoidalariga tegilmaydi.
