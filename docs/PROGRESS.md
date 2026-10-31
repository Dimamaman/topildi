# Topildi — loyiha holati

> Oxirgi yangilanish: 2026-10-30

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
| Push bildirishnomalar | 🟡 `topildi` functions deploy qilingan (2026-10-28); haqiqiy iPhone'da sinov qoldi |
| Bildirishnomalar sahifasi | ✅ Firestore'dan o'qiydi, bo'sh holati yangi dizaynda |
| Brend ("t." logo, ikonka, splash) | ✅ tayyor |
| Eʼlonni tahrirlash | ✅ tayyor, rules deploy qilingan |
| Javobsiz so'rov: eslatma va bekor qilish | ✅ deploy qilingan (24 soatda eslatma, 3 kundan keyin bekor qilish) |
| Eʼlon rasmlari (`topildi/uploads/{uid}/`) | 🟡 kod commit qilingan; **`storage.rules` deploy qilinganini tekshirish kerak** |
| Pul topish: eʼlonni tepaga ko'tarish (Click + Payme) | 📝 reja tayyor, kod yo'q (pastda) |
| Xarita | ⏸ `Features.map` bilan yashirilgan |
| Android | ⏳ sozlanmagan |
| Foydalanish shartlari, Maxfiylik siyosati | ✅ ilova ichida (uz/kirill/ru), aloqa: Telegram @dimamamann |
| Hisobni o'chirish | 🟡 kod tayyor; **`topildiDeleteAccount` deploy qilinishi kerak** |
| Shikoyat va bloklash (App Store 1.2) | 🟡 ishlayapti: shikoyat Telegramga keladi, moderator tugmalari bosiladi (2026-10-30 da qurilmada tekshirilgan). Qayta shikoyat qilish uchun ilovaning yangi build'i kerak |

**Branchlar (2026-10-26):** hamma ish `main` ga birlashtirildi — PR #3 → `firebase-phase1` → `main` (fast-forward). Yangi ish `main` dan alohida branch'da boshlanadi.

**Tekshiruv (2026-10-29):** `flutter analyze` toza; `flutter test` — 103 ta test o'tadi; `functions`: `npm test` — 34 ta; `flutter build ios --simulator --debug` muvaffaqiyatli; Firestore rules, indekslar va `topildi` functions deploy qilingan.

**Tekshiruv (2026-10-30):** `flutter analyze` toza; `flutter test` — 110 ta o'tadi (`auth_flow_test` oldindan yiqilardi, bu sessiyaga aloqasi yo'q); `functions`: `npm test` — 47 ta; `firestore.rules` va `topildi` functions deploy qilingan.

> **Test rejimi** (bekor qilish kutishsiz va urinishni sarflagan holda) 2026-10-28 da sinovdan keyin qaytarildi: kutish yana 3 kun, bekor qilingan so'rov o'chiriladi va urinish qaytadi; rules deploy qilingan.

---

## ✅ Qilingan ishlar

### 1. Dizayn (iOS 26 uslubi)

**Glass UI tizimi:** `GlassSurface` (blur, saturatsiya, chekka yorug'ligi, soya), `TGlass` tokenlari, glass header va sheet, `OverlayEntry` asosidagi pull-down menyu (bosib-sudrab tanlash).

**Ekranlar:** Kirish (Telegram bot orqali, bitta bosish), Tanishib olaylik (orbita avatar, emoji, rang), Lenta (2 ustunli grid, skeleton, tur tablari, bo'sh holatda glass ikonka + "+" ga strelka), Mening eʼlonlarim, Filtrlar sheeti, Hudud menyusi, Bildirishnomalar, Chatlar, Chat, Profil, barcha dialoglar (glass alert).

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
| Auth | `firebase_auth_repository.dart` — Telegram bot orqali kirish (`topildiTgStart` / `topildiTgClaim` / `topildiTgWebhook`, SMS kod o'rniga) va Google; profil `topildi_users/{uid}` |
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

### 7. 2026-10-28 sessiyasi

**Ekranlar (dizayn bo'yicha qayta qilindi):**
- **"Eʼlon joylandi!"** (`posted_page.dart`): "katta matn + suriladigan kartalar", Instagram uslubidagi tasdiq belgisi, "Faol" chip, 3 ta "Keyin nima boʻladi?" kartasi (faol karta ko'k, qolganlari oq; 3.5 s da o'zi aylanadi), Ulashish tugmasi (`share_plus`), kirish animatsiyasi.
- **Ko'rib chiqish:** tayyorlik halqasi 99% da to'xtaydi (e'lon qilish oxirgi qadam); tahrirlashda 100%.
- **Chatlar, Bildirishnomalar bo'sh holati:** Lenta bilan umumiy `GlassEmptyIcon` (`lib/core/widgets/glass_empty_icon.dart`); Chatlar'da qulf belgisi, blok ekran markazida; Bildirishnomalar'da 3 ta namuna qatori, tizimda o'chiq bo'lsa ogohlantirish va "Yoqish".
- **"Egaligingizni tasdiqlang"** (`claim_page.dart`): katta savol, javob maydoni, dalil rasm kapsulasi, 3 ta kalit (urinishlar; rad etilgandan keyin bittasi "tushadi"), rad etilgan va urinishlar tugagan holatlar. Savol ostidagi izoh va yordamchi chiplar keyinroq olib tashlangan.
- **"Soʻrovlar"** (`claims_page.dart`, muallif uchun): tepada eʼlon nomi va miniatyura; har so'rov bitta kartada — "SIZ YOZGAN BELGI" (och ko'k, ilova uslubida) va "{ISM} JAVOBI" ustma-ust, orasida "VS"; "{vaqt} · {n}-urinish", holat chipi; pastda "✕ Mos emas" (tasdiqsiz, 5 s "Bekor qilish" snackbar'i, keyin rad etish yuboriladi; sahifadan chiqilsa ham) va "✓ Qabul qilish" (tasdiq + loading kapsula → chat); qabul qilinganda "Chatga oʻtish". 2+ so'rov yonma-yon suriladi ("Soʻrovlar · 1 / 3"). `Claim.attempt` qo'shildi (Firestore'dagi `attempt` maydoni). Tugmali snackbar o'zi yopilmaydi — 5 s tugaganda kod yopadi.
- **Eʼlon sahifasi (muallif):** "N ta yangi soʻrov" kartasi oq, ko'k `front_hand` ikonka kvadrati va ko'k son nishoni bilan.
- Chatlar tab ikonkasi uch chiziqli `chat`; profil statistikasida ruscha uzun yozuv faqat o'zi kichrayadi.

- **"Soʻrov yuborildi!"** (`claim_sent_page.dart`, SY1): "Eʼlon joylandi!" uslubida — ✕ (glass), buyum qatori (72 miniatyura + `send` nishoni, "Topuvchi/Egasi: {ism} · {tuman}", bosilsa eʼlon), katta ikki qatorli sarlavha, 3 qadamli vaqt chizigʻi (aylanuvchi halqa, "Kamroq harakat"da statik), "Lentaga qaytish"; kirish animatsiyasi S3 bilan bir xil. "Odatda bir necha soat" va sariq/yashil belgilar olib tashlandi; "Soʻrovlarimni koʻrish" havolasi qoʻyilmadi (ilovada bunday sahifa yoʻq). ✕ va "orqaga" Lentaga olib boradi. Ekran ochiq turganda soʻrov real vaqtda kuzatiladi (`WatchClaim`, `ClaimSentCubit`): qabul qilinsa "Qabul qilindi!" + "Chatga oʻtish", rad etilsa "Javob mos kelmadi. Yana {n} ta urinish qoldi" + "Qayta urinish" (urinish qolmasa "Lentaga qaytish").

- **"Buyum egasiga qaytdi!"** (`success_page.dart`, BQ1, 2026-10-29): S3/SY1 uslubida — ✕ (glass), buyum qatori (72 miniatyura — eʼlonning birinchi rasmi yoki kategoriya rangi, `handshake` nishoni, "Egasi: {ism} · {vaqt}", ism yoʻq boʻlsa faqat vaqt; egasi uchun "Topuvchi: …"), oʻng yuqorida 14 ta konfetti, katta ikki qatorli sarlavha (tor ekranda qator kichrayadi, boʻlinmaydi), hisoblagich kartasi ("Siz endi **n ta buyumni** egasiga qaytardingiz", n = 1 da `volunteer_activism` + "birinchi"; raqam 0 dan sanaladi), egasining rahmat xati boʻlsa — undan keyin alohida karta, "Lentaga qaytish" + 56 doira ulashish (`share_plus`). Yashil rang va "Mehribon qoʻshni" olib tashlandi; egasi koʻrganda hisoblagich chiqmaydi. `ReturnSummary` ga eʼlon id, kategoriya, tint, rasm va `returnedAt` qoʻshildi (`ChatRemoteDataSource.returnedItem` — chat'dagi `returnedAt` va eʼlonning `photoUrls[0]`). Backend/rules oʻzgarmadi.

- **Chat ekrani** (`chat_page.dart`, CA, 2026-10-29): "glass kapsula" uslubi, ikki holat — faol va yopilgan.
  - Xabarlar butun ekran bo'ylab skroll bo'ladi; ustida suzuvchi glass elementlar: tepa panel (44 doira "orqaga", 52 kapsula — avatar bosh harfi, ism, `verified` + "Topuvchi"/"Egasi", 44 doira "…"), buyum kartasi (48 miniatyura — eʼlonning birinchi rasmi yoki kategoriya, "{tuman} · {sana}", holat chipi "Faol chat" / "Qaytarildi"), pastki panel. Tepada radial yorug'lik, tepa/past gradientlar.
  - Tizim xabarlari ixcham kapsulalar: `key` "Javob yashirin belgiga mos keldi · Chat ochildi", `handshake` "Buyum egasiga qaytarildi · {vaqt}". **Xavfsizlik eslatmasi chatda ko'rsatilmaydi** (`MessageKind.safety` filtrlanadi, datada qoldi). Kun ajratgichlari "Bugun" / "Kecha" / "27-oktabr".
  - Pufakchalar: radius 22, "dum" 6 faqat ketma-ket xabarlarning oxirgisida; vaqt Telegram uslubida (sig'sa oxirgi qatorda); `done` / `done_all`.
  - Yozish paneli: maydon 5 qatorgacha o'sadi, bo'sh bo'lsa yuborish 0.45 va bosilmaydi. **📍 tugma olib tashlandi** ("+" qo'yilmadi — u faqat joylashuv matnini yozardi). Ro'yxatning pastki paddingi panelning haqiqiy balandligiga qarab o'zgaradi (uzun matn, 130% shrift).
  - Yopilgan chat: glass kapsula "**Chat yopildi.** Yozishmalar saqlanadi." + "Eʼlonni koʻrish"; real vaqtda qaytarilsa 250 ms fade + 8 px ko'tarilish, klaviatura yopiladi.
  - **Topuvchining "Qaytarildi" tugmasi "…" menyusiga ko'chdi** ("Buyum qaytarildi", tasdiq dialogi o'sha). Ko'rinarliroq qilish kerak bo'lsa — kartadagi chipni topuvchi uchun tugmaga aylantirish mumkin.
  - Yashil rang olib tashlandi; qorong'i tema ColorScheme tokenlari orqali (`primaryContainer` #233a72 va h.k.).
  - `ChatCubit` endi eʼlonni bir marta yuklaydi (`GetListingDetail` → `ChatState.listing`) — tuman, sana, rasm uchun; yuklanmasa karta faqat nom va ikonka bilan. `injection.config.dart` qo'lda yangilandi. Backend/rules oʻzgarmadi.
  - Golden skrinshotlar bilan tekshirildi (390 yorug'/qorong'i, 360 + 130% matn); `finder_flow_test` yangi UI'ga moslandi.

- **Eʼlon joylash — barcha hududlar** (2026-10-29): 3-qadamda "Toshkent" yozuvi endi bosiladi (ko'k, `expand_more`) → hudud menyusi (filtrlardagi 14 ta hudud); tuman chiplari tanlangan hududdan (`Regions.districtsOf`), hudud almashsa tuman tozalanadi. `CreateDraft.city` (+ `withCity`), `CreateFlowCubit.setCity`, tahrirda eʼlonning `city` si, repository `city` ni yozadi (avval doim `'Toshkent'` edi). **"Aniqlash":** Toshkent tuman markazidan 10 km ichida → Toshkent + tuman; aks holda eng yaqin viloyat markazi (350 km gacha, Toshkent shahri hisobga olinmaydi — viloyat uni o'rab turadi), tuman `Geocoder.areaFor` nomidan (`Regions.matchDistrict`: "Urgut tumani" / "Urgut District" → "Urgut"); topilmasa "Hudud aniqlandi: {hudud}. Tumanni tanlang."; 350 km dan uzoq — "Siz Oʻzbekistondan tashqaridasiz". Yangi: `Regions.regionCenters`, `pointOf`, `locate`, `matchDistrict`; `CreateSectionLabel.onValuePick`. Rules allaqachon `city` ga ruxsat beradi — deploy kerak emas. Testlar: `regions_test`, `create_flow_test` ga hudud almashtirish.

- **Klaviatura (iOS uslubi, butun ilova, 2026-10-29):** har qanday skroll surilsa klaviatura yopiladi (`app.dart` → `_AppScrollBehavior.getKeyboardDismissBehavior` = `onDrag`; alohida `keyboardDismissBehavior` yozish shart emas); boshqaruv elementi bo'lmagan joyga tap qilinsa yopiladi (`MaterialApp.builder` dagi `GestureDetector` → `unfocus`; tugma, chip va maydonlar tap'ni o'zi oladi). Fokuslangan maydon suzuvchi tugma ostida qolmasligi uchun `scrollPadding`: eʼlon joylash (`CreateField`, `createFormBottomPadding` — sahifa `resizeToAvoidBottomInset: false`) va so'rov javobi (`claim_page`, pastdan 140). Test: `test/core/keyboard_test.dart` (iOS). Maydonning tugma ustiga ko'tarilishi haqiqiy iPhone'da tekshirilmagan.
- **Chat tuzatishlari (2026-10-29):** qalin matnlar `.inter(FontWeight…)` ga o'tkazildi (oddiy `fontWeight` google_fonts bilan sun'iy qalinlik beradi); yuborish tugmasidagi `Opacity` olib tashlandi — blur soyali element ustida Impeller `SetInheritedOpacity … CanAcceptOpacity` xatosini chiqarardi, endi ranglar xiralashtiriladi. Ilovada xato yo'qolgani hali tasdiqlanmagan; yozish paneli ↔ yopilgan kapsula almashinuvidagi fade ham shunday xato berishi mumkin.

**Brend:** yangi "t." logo — `lib/core/widgets/topildi_logo.dart` (`TopildiMark`, `TopildiAppIcon`, `TopildiWordmark`, belgi SVG path'idan chiziladi). Arxivdagi PNG'lar buzuq edi, `assets/brand/` dagi PNG'lar shu path'dan qayta yasalgan. iOS/Android launcher ikonkalari (`flutter_launcher_icons`, Android 13 monoxrom bilan) va native splash (`flutter_native_splash`, ko'k fon) — sozlamalar `pubspec.yaml` da. Flutter splash belgini native splash bilan bir joyda chizadi.

**Umumiy loading kapsula** — `lib/core/widgets/topildi_loader.dart` (`TopildiLoader.run`): Dynamic Island ostidan tushadi, orqa fonni va "orqaga" ni bloklaydi, "tugadi" / xato + "Qayta". Ulangan: eʼlonni o'chirish, eʼlon joylash, profilni saqlash, chiqish, so'rov yuborish, eʼlonni saqlash (tahrir), so'rovni bekor qilish.

**Eʼlonni tahrirlash:** "Tahrirlash" → `/create/edit/:id` — Ko'rib chiqish ekrani mavjud eʼlon bilan to'ldiriladi, qadamlar shu yerdan ochiladi, pastda "Saqlash". Tur o'zgarmaydi; so'rov kelgan bo'lsa yashirin belgi bloklanadi; saqlanmagan o'zgarish bilan chiqishda tasdiq. Rules: muallif faol eʼlonda faqat tahrirlanadigan maydonlarni va yashirin belgini o'zgartira oladi.

**Javobsiz so'rovlar:**
- **Eslatma:** `topildiRemindPendingClaims` (har soat) — 24 soatdan ko'p kutgan so'rov uchun muallifga bitta push (`remindedAt` bilan belgilanadi). Indeks: `topildi_claims` (`status`, `createdAt`).
- **Bekor qilish:** so'rov yuborgan odam "Soʻrov yuborildi" ni bosib, 3 kundan keyin so'rovni qaytarib oladi; urinish qaytariladi, dalil rasm o'chadi. Rules faqat egasiga, faqat `pending` holatda ruxsat beradi.

**Qabul qilingan so'rovdan keyin "Bu meniki" qaytib chiqardi (tuzatildi, 2026-10-29):** ilova so'rovchining faqat `pending` so'rovini bilardi; qabul qilingach eʼlonda yana "Bu meniki" chiqar, forma noto'g'ri "Javob mos kelmadi" ko'rsatar, yangi so'rovni server rad etib "Ruxsat yoʻq" chiqardi. Endi `ClaimTarget.acceptedClaimId` va `rejected` bor: eʼlon sahifasida "Chatga oʻtish" (chat id = claim id), formada qabul qilingan/kutilayotgan holatda yuborish tugmasi yo'q ("Soʻrovingiz qabul qilindi…" / "…hali koʻrib chiqilmoqda"), "Javob mos kelmadi" faqat haqiqatan rad etilganda. `ClaimRepositoryImpl.submit` qabul qilingan yoki kutilayotgan so'rov bo'lsa `ValidationFailure` qaytaradi. Rules o'zgarmadi.

**Loading kapsula xato matni:** Firebase'ning inglizcha texnik xabarlari ("User is not authorized…") endi ko'rsatilmaydi — faqat "Internetni tekshiring", "Ruxsat yoʻq. Qayta kirib koʻring" yoki validatsiya matni; asl sabab logda (`TopildiLoader._reason`).

**Eʼlon rasmlari yangi papkada:** rasmli eʼlon joylashda Storage `unauthorized` xatosi chiqardi (eski qoida Firestore'ni o'qiydigan `firestore.exists(...)` ga tayanardi; Storage'ning Firestore ruxsati bor ekani deploy'da tasdiqlangan, sabab aniqlanmadi). Endi rasmlar `topildi/uploads/{uid}/{eʼlonId}_{n}.jpg` ga yuklanadi (`FirePaths.listingPhoto`), qoida faqat uid'ni tekshiradi. Eʼlon o'chirilganda rasmlar URL bo'yicha o'chiriladi; eski eʼlonlarning `topildi/listings/{id}/` dagi rasmlari ham tozalanadi. Eski eʼlonlarning rasmlari joyida qoladi.

**Test rejimi** (bekor qilish kutishsiz, so'ng urinishni sarflagan holda) sinovdan keyin qaytarildi. `ClaimTarget.cancelUsesAttempt` bayrog'i va `ClaimStatus.cancelled` kodda qolgan (`false`, ishlatilmaydi); `true` qilish uchun claimant'ning `pending → cancelled` update qoidasini ham qaytarish kerak.

**Boshqa:** O'zbekistonning 14 ta hududi va ~190 tuman/shahar filtrlarda (`regions.dart`); Chatlar refresh'i endi qotib qolmaydi (`ChatListCubit.load`); "Saqlash" va boshqa tugmalar `CreatePrimaryButton` uslubida.

### 8. 2026-10-30 sessiyasi — shikoyat va bloklash (SH1–SH6, BL1–BL4)

App Store Guideline 1.2 talabi: haqiqiy shikoyat, bloklash, moderatsiya va nomaqbul kontentga nol tolerantlik. Reja — `docs/SHIKOYAT_PLAN.md`, UI topshirigʻi — `TOPSHIRIQ-shikoyat-bloklash-ui.md`.

**Maʼlumotlar va qoidalar (`firestore.rules`):**
- `topildi_reports/{targetType}_{targetId}_{reporterUid}` — id shunday tuzilgani uchun bitta odam bitta narsaga faqat bir marta shikoyat qila oladi. Faqat `create` mumkin; ilova o'z hujjatini `get` qila oladi (sheet "allaqachon yuborilgan" ni shundan biladi), `list` / `update` / `delete` yopiq (9-bo'limda `update` yopilgan shikoyatni qayta yuborish uchun ochildi). `reportedUid` nishondan kelib chiqishi tekshiriladi: eʼlon uchun — uning muallifi, chat uchun — suhbatdagi ikkinchi aʼzo; o'z eʼloningizga shikoyat qilib bo'lmaydi.
- `topildi_users/{uid}/blocked/{otherUid}` — ro'yxatni egasi yozadi va o'qiydi; bloklangan odam faqat **o'z** yozuvini o'qiy oladi. Chatdagi "yozib bo'lmaydi" bannerini ko'rsatish uchun shu kerak — yaʼni "meni falonchi bloklaganmi?" degan savolga javob beradi.
- Bloklangan odam xabar ham, "Bu meniki" so'rovi ham yubora olmaydi: `blockedBy()` tekshiruvi `topildi_claims` create va chat `messages` create ichida.
- `ListingStatus.hidden` — faqat server qo'yadi; muallif undan chiqa olmaydi, yashirilgan eʼlonni tahrirlay ham, "Qaytarildi" deb yopa ham olmaydi.

**Cloud Functions:**
- `functions/src/report.ts` — sof funksiyalar (test qilinadi): moderatorga ketadigan Telegram xabari matni (HTML, foydalanuvchi yozgani escape qilinadi), sabab nomlari ("Soxta eʼlon", chatda "Aldov"), moderator tugmalari va `callback_data`, `hideThreshold = 3`.
- `functions/src/moderate.ts` — Firestore va Bot API: dalilni shikoyatga nusxalash (eʼlon tavsifi, joyi va rasm URL'lari yoki chatning oxirgi 20 xabari), bir nishondagi shikoyatlarni sanash (hujjat id'si bo'yicha — qo'shimcha indeks kerak emas), avtomatik yashirish, moderator bosgan tugmani bajarish.
- `topildiOnReportCreated` — yangi shikoyat yozilganda ishlaydi. Bitta eʼlonga 3 xil odam shikoyat qilsa, eʼlon `hidden` bo'ladi va lentadan yo'qoladi. (9-bo'limda yoniga `topildiOnReportReopened` qo'shildi.)
- `topildiTgWebhook` endi `callback_query` ni ham oladi (`parseCallback`, `telegram.ts`): "🙈 Eʼlonni yashirish", "↩️ Qaytarish", "✅ Yopish". Faqat `TELEGRAM_ADMIN_CHAT_ID` dan kelgan bosishlar qabul qilinadi; kirish oqimiga tegmaydi.
- `account.ts` — hisob o'chirilganda foydalanuvchi **yuborgan** shikoyatlar ham o'chadi (`blocked` ro'yxati `topildi_users/{uid}` bilan birga ketadi). Unga qilingan shikoyatlar dalil sifatida qoladi.
- Sozlamalar: `TELEGRAM_ADMIN_CHAT_ID` (`functions/.env`, sir emas) va `TELEGRAM_BOT_TOKEN` (Secret Manager). **Tokenni `.env` ga yozmang** — ikkala joyda bo'lsa Cloud Run "Secret environment variable overlaps non secret environment variable" deb deploy'ni rad etadi.

**Ilova:**
- `lib/features/report/` — `ReportTarget`, `ReportReason`, `SubmitReport`, `CheckReported`, Firestore va mock datasource, `report_sheet.dart`.
- `lib/features/block/` — `BlockedUser`, `BlockUser` / `UnblockUser` / `WatchBlocked` / `GetBlockState`, datasource'lar, `BlockedCubit`, `blocked_page.dart`, `block_sheet.dart`.
- **SH1** — boshqa odamning eʼlonida "Ulashish" o'rnida "…": Ulashish | Shikoyat qilish, Muallifni bloklash. O'z eʼloningizda menyu o'zgarmadi.
- **SH2** — chat "…": Buyum qaytarildi (topuvchida), Eʼlonni ko'rish | Shikoyat qilish, Bloklash (bloklangan bo'lsa "Blokdan chiqarish"). Eski soxta tasdiq oynasi olib tashlandi.
- **SH3/SH4** — shikoyat sheeti: nishon kartasi, 5 ta sabab chipi (galochkasiz, bittasi tanlanadi), ixtiyoriy izoh (≤300, hisoblagich bilan), "Shikoyat anonim · 24 soat ichida ko'rib chiqiladi". Yuborilganda sheet yopilmaydi — ichidagi kontent **SH5** ("Shikoyatingiz yuborildi") ga almashadi. **SH6** — takroriy shikoyatda ochiladigan qisqa sheet.
- **BL1** — bloklash tasdigʻi (3 qator tushuntirish). **BL2** — chatda yozish paneli o'rnida kapsula: "Siz bloklagansiz." + "Blokdan chiqarish"; sizni bloklagan odam bilan bo'lsa tugmasiz matn, kim bloklagani ko'rsatilmaydi. **BL3** — Profil → Sozlamalar → "Bloklanganlar" (soni bilan), blokdan chiqarishda 5 soniyalik "Bekor qilish". **BL4** — bo'sh holat.
- Bloklangan odamning eʼlonlari lenta, xarita va qidiruvdan chiqadi — `ListingRepositoryImpl` da bir joyda filtrlanadi; blok o'zgarsa `changes` oqimi lentani yangilaydi.
- Yashirilgan eʼlon muallifiga "Tekshiruvda" deb ko'rinadi (Mening eʼlonlarim va Profil kartasi).
- Foydalanish shartlarining 7-bandi qayta yozildi: nol tolerantlik, 24 soat, shikoyat va bloklash qanday ishlashi (uz / kirill / ru). Yangi matnlar `ru.dart` ga qo'shildi, kirill avtomatik.

**Yo'l-yo'lakay tuzatilgan xato:** `showPullDownMenu` menyu balandligini har bir qator bitta qatorlik matn deb hisoblardi. Matni ikki qatorga tushgan band menyuning kesilgan chegarasidan chiqib ketar va umuman bosilmas edi ("Muallifni bloklash" aynan shunday edi). Endi menyu haqiqiy balandligini oladi, cheklov — ekrandagi bo'sh joy.

**Testlar:** `functions/src/test/report.test.ts` (xabar matni, escape, tugmalar, yashirish chegarasi) — 13 ta yangi; `test/features/report/report_test.dart` (shikoyat oqimi, takroriy shikoyat, o'z eʼlonida bandlar yo'qligi) va `test/features/block/block_test.dart` (eʼlondan bloklash + lentadan yo'qolishi, Bloklanganlar sahifasi, chatdagi banner) — 5 ta yangi.

**Deploy (2026-10-30):** `firestore.rules` va `topildi` functions deploy qilingan, `topildiOnReportCreated` yaratildi. Bot token `/revoke` bilan yangilangan, shuning uchun webhook qayta ulanishi kerak: `setWebhook` → `https://topilditgwebhook-5o72enezwa-uc.a.run.app`, `allowed_updates=["message","callback_query"]`. **`callback_query` bo'lmasa moderator tugmalari ishlamaydi.** Haqiqiy qurilmada sinov qolgan.

### 9. 2026-10-30 (ikkinchi sessiya) — shikoyat Telegramga yetmadi, keyin qayta shikoyat

**Muammo:** shikoyat Firestore'ga tushdi, lekin Telegramga kelmadi. Funksiya logida:
`topildionreportcreated: Error: sendMessage: Bad Request: BUTTON_DATA_INVALID`.

Sabab — Telegram `callback_data` ni 64 baytdan oshishiga yo'l qo'ymaydi va **bitta** tugma oshsa butun xabar yuborilmaydi. Tugmaga to'liq shikoyat id'si solinardi: `r:restore:` (10) + `listing_` (8) + 20 belgilik hujjat id + `_` + 28 belgilik uid = 67 bayt. Testlarda `l1`, `u_me` kabi qisqa id'lar bo'lgani uchun bu chegara hech qachon sinalmagan edi.

**Yechim — qisqa `modKey`:**
- `report.ts`: `maxCallbackBytes = 64`, `modKeyLength = 12`; `callbackData` / `parseCallbackData` / `moderationKeyboard` endi to'liq id emas, qisqa kalit bilan ishlaydi (`r:restore:aB3-_xK9pQ2w` = 22 bayt).
- `moderate.ts`: `newModKey()` (9 bayt tasodifiy → base64url) kalit yaratadi, u shikoyat hujjatiga `modKey` maydoni sifatida `evidence` bilan birga yoziladi. Tugma bosilganda shikoyat `where("modKey", "==", ...)` bilan topiladi — bitta maydon bo'yicha tenglik, demak Firestore'ning avtomatik indeksi yetarli.
- Xabar matnida to'liq id avvalgidek `<code>` ichida qoladi, moderator hujjatni Console'dan topa oladi.
- Yangi test: har bir tugmaning `callback_data` si 64 baytdan oshmasligi.

**Yo'l-yo'lakay tekshirilgani (hammasi joyida edi):** bot `@menikitopildi_bot`, `TELEGRAM_BOT_TOKEN` Secret Manager'da, `TELEGRAM_ADMIN_CHAT_ID=-5544898008` → `Topildi moderatsiya` guruhi (`getChat` javob berdi, bot a'zo). **Webhook ham ulangan ekan:** moderator tugmasi bosilganda `callback_query` keldi va xabar "✅ Yopildi" ga o'zgardi — 8-bo'limdagi "webhook qayta ulash kerak" bandi shu bilan yopildi.

**Ikkinchi muammo:** shikoyat yopilgandan keyin ham o'sha odam o'sha nishonga qayta shikoyat qila olmasdi — ilova `exists` ni (hujjat bor-yo'qligini) tekshirardi, qoidalarda esa `update` butunlay yopiq edi. Yaʼni bir marta yopilgan ish qurbonni umrbod jim qilardi.

**Yechim — yopilgandan keyin qayta yuborish mumkin, ochiq turganda yo'q:**
- `firestore.rules`: `update` endi shikoyat egasiga ochiq, faqat `resource.data.status != 'open'` bo'lganda va `validReport` + `validTarget` o'tsa. `validReport` hujjat id'sini `{type}_{targetId}_{uid}` deb talab qilgani uchun nishon ham, shikoyatchi ham o'zgarmaydi. Ilova butun hujjatni `set()` bilan qayta yozadi, shuning uchun serverning eski `evidence` / `modKey` / `moderatedAt` maydonlari tozalanadi va funksiya ularni yangidan to'ldiradi.
- Ilova: `ReportRemoteDataSource.exists` → `hasOpenReport` (`status == 'open'` ni tekshiradi). Mock'da `close()` metodi — moderatorning "Yopish" tugmasi o'rnida.
- `topildiOnReportReopened` (`onDocumentUpdated`) — `isReopened(before, after)` (status yopiqdan `open` ga qaytgani) rost bo'lsa o'sha `handleReport` ni chaqiradi, moderatorga ikkinchi xabar ketadi.
- **Nega alohida funksiya, `onDocumentWritten` emas:** nom o'zgarsa deploy eski funksiyani o'chirishi kerak bo'ladi, interaktiv bo'lmagan deploy esa uni o'chirmay qoldirishi mumkin — natijada ikkita trigger bitta shikoyatga ikki marta xabar yuborardi.
- **Tsikl yo'q:** funksiyaning o'z yozuvi (`evidence`, `reports`, `modKey`) `status` ga tegmaydi, shuning uchun `isReopened` false qaytaradi.
- 3 ta shikoyatda avtomatik yashirish hisobi o'zgarmadi: bitta odam bitta nishon uchun baribir bitta hujjat.

**Deploy (2026-10-30):** ikki marta — avval `BUTTON_DATA_INVALID` tuzatishi (functions), keyin `firestore.rules` + functions (`topildiOnReportReopened` yaratildi). **Qolgani:** ilovaning yangi build'i chiqmaguncha qayta shikoyat qilish foydalanuvchilarda ishlamaydi (tekshiruv Flutter kodida).

**Testlar:** `functions` — 49 ta (yangi: `callback_data` chegarasi, `isReopened`); `flutter analyze` toza; `report_test.dart` ga yopilgandan keyin qayta shikoyat qilish qadami qo'shildi.

### 10. 2026-10-30 (uchinchi sessiya) — shikoyat sheeti sababsiz (SH3/SH4 qayta ishlandi)

Yangi UI topshirigʻi (`TOPSHIRIQ-shikoyat-bloklash-ui.md`): shikoyatda **sabab tanlash olib tashlandi**, foydalanuvchi faqat izoh yozadi.

- `report_sheet.dart`: 5 ta sabab chipi va `_reasonLabel` / `_reasonIcon` / `_ReasonChip` oʻchirildi. Firestore talab qiladigan `reason` maydoniga ilova avtomatik `ReportReason.other` yuboradi (rules va functions oʻzgarmadi — Telegram xabarida asosiy maʼlumot izoh).
- Yuqori panel endi Filtrlar sheeti bilan bir xil: chapda 44×44 glass "Yopish", markazda "Shikoyat qilish" 17px w600, oʻngda 44px boʻsh joy.
- Izoh **majburiy**: yorliq "IZOH" (ilgari "IZOH · IXTIYORIY"), yangi placeholder "Nima boʻldi? Batafsil yozing…", maydon avtomatik fokusda ochiladi (klaviatura darhol chiqadi), balandligi 190 (klaviatura ochilganda 150, joy yetmasa undan ham kichrayadi — `Flexible` + `expands: true`), radius 22, fokusda 2px `primary` va koʻk soya.
- "Yuborish" izoh (boʻshliqlarsiz) **10 belgidan** kam boʻlsa oʻchiq (opacity 0.45); tugmada ikonka yoʻq — faqat matn. Klaviatura ochilganda "Shikoyat anonim · …" qatori yashiriladi.
- Klaviatura ustida turish `showGlassSheet` ning oʻzida bor edi (`mq.viewInsets.bottom`) — qoʻshimcha oʻzgarish kerak boʻlmadi.
- `minReportComment = 10` — `report.dart` da, `maxReportComment` yonida.
- `ru.dart`: 'SABAB', 'IZOH · IXTIYORIY', 'Spam', 'Soxta eʼlon', 'Aldov', 'Firibgarlik', 'Haqoratli' va eski placeholder olib tashlandi; 'IZOH' va yangi placeholder qoʻshildi. `ReportReason` enumi oʻzi qoldi (eski shikoyatlar va moderator asboblari uchun).
- Qolgan ekranlar (SH1, SH2, SH5, SH6, BL1–BL4) topshiriqqa mos edi — tegilmadi.

**Testlar:** `report_test.dart` sababsiz oqimga moslandi (10 belgidan kam izohda "Yuborish" ishlamasligi, `reason: other` yuborilishi). `flutter analyze` toza; `flutter test` — faqat eski `auth_flow_test.dart` yiqiladi (toza `main` da ham yiqiladi, bu ishga aloqasi yoʻq).

### 11. 2026-10-30 (toʻrtinchi sessiya) — SH6 bosqichli sheet

Yangilangan topshiriq (`TOPSHIRIQ-shikoyat-bloklash-ui_1.md`): "Allaqachon yuborilgan" qisqa kartasi oʻrniga **bosqichlar** koʻrsatiladigan toʻliq sheet.

- Endi ilova oʻz shikoyatining **sanasini** ham oʻqiydi: `hasOpenReport` (bool) oʻrnida `openReport` → `OpenReport(createdAt)`. `ReportRemoteDataSource`, Firestore va mock manbalar, `ReportRepository.openReport`, `CheckReported` shunga moslandi. **`firestore.rules` oʻzgarmadi** — shikoyat egasining `get` i allaqachon ochiq edi (`allow get: ... isMe(resource.data.reporterId)`).
- SH6 sheeti SH3 bilan bir xil: yuqori panel (chapda 44×44 glass X, markazda "Shikoyat qilish"), nishon kartasi, ostida oq holat kartasi (radius 22, padding 16/2). Sarlavha "Shikoyatingiz allaqachon yuborilgan" 17px w800, ostida 3 bosqich: 30×30 belgi + 2px vertikal chiziq, oraliq 12.
  1. **Yuborildi** — `primary` doira, oq `check` 18px; izohi `TDate.relative(..., withTimeForOld: true)` → "Bugun, 14:20".
  2. **Moderator koʻrib chiqmoqda** — #e3ebfc doira, atrofida 5px `primary` 12% halqa (spread shadow), ichida aylanuvchi 14px halqa; "Kamroq harakat" da statik.
  3. **Natija** — 2px #dce2ec halqa, `notifications` 16px, matn kulrang.
- Tugma yoʻq — X yoki pastga surib yopiladi.
- **3-bosqich izohi**: "Bildirishnoma orqali xabar beramiz" oʻrniga **"Moderator qarori shu yerda koʻrinadi"** — qaror push qilib yuborilmaydi, lekin sheetning oʻzida koʻrinadi (pastda).
- **Natija sheetda koʻrinadi (foydalanuvchi qarori, 2026-10-30).** Shikoyat yopilgandan keyin ham SH6 ochiladi: 1 va 2-bosqich ✓, 3-bosqich "Koʻrib chiqildi" + `gavel` belgisi; izohi `resolved` → "Chora koʻrildi. Rahmat!", `dismissed` → "Qoidabuzarlik topilmadi". Pastda **"Yana shikoyat qilish"** tugmasi — bosilganda oʻsha sheet ichida forma ochiladi, yaʼni yopilgan ish baribir hech kimni jim qilmaydi.
  - Shu sabab `OpenReport` → `MyReport(status, createdAt)`, `ReportStatus { open, resolved, dismissed }`; datasource `myReport` hujjatni holatidan qatʼi nazar qaytaradi, notaʼnish `status` esa `open` deb qaraladi. Sheet bir widget: `_Phase { status, form, sent }`.
  - **Bosqichlar bir xil qadamda (2026-10-30).** Avval yopilgan holatda 2-bosqichning izohi boʻlmagani uchun doiralar orasidagi masofa teng emas edi. Endi har bir bosqich izoh qatorini (min 16dp) doim band qiladi, sarlavha balandligi 20dp ga qotirilgan — qator balandligi 58dp, doiralar teng oraliqda (widget testida oʻlchab tekshirildi).
  - Yopilgan holatdagi matnlar: 2-bosqich "Koʻrib chiqildi", 3-bosqich doim "Natija" (ikkala holatda ham), izohi `resolved` → "Chora koʻrildi. Rahmat!", `dismissed` → "Qoidabuzarlik topilmadi". 3-bosqich belgisi: `verified_user` (koʻk, toʻla) yoki kulrang `remove`.
  - **Real vaqtda (2026-10-30).** SH6 ochiq turganda moderator qarori oʻzi tushadi: `watchMyReport` → `topildi_reports/{id}` hujjatining `snapshots()` i, `WatchReport` usecase, sheet ichida `StreamBuilder` (boshlangʻich qiymat — ochishdan oldingi `get`). Moderator Telegramda tugmani bossa, bosqichlar sheet yopilmasdan yangilanadi va "Yana shikoyat qilish" tugmasi paydo boʻladi. `firestore.rules` oʻzgarmadi — bitta hujjatga listener ham `get` qoidasidan oʻtadi. Mock datasource ham `StreamController` bilan jonli (test shuni tekshiradi).
  - Diqqat: `functions/src/report.ts` dagi `statusAfter` moderatorning **"Yopish"** va **"Eʼlonni yashirish"** tugmalarini bir xil `resolved` ga oʻtkazadi, yaʼni oddiy yopishda ham "Chora koʻrildi. Rahmat!" chiqadi. Aniqroq matn kerak boʻlsa, backendda `close` uchun alohida holat kerak.
- `ru.dart`: 'Allaqachon yuborilgan' va ikkita "Bu eʼlonga/suhbatga…" matni olib tashlandi; 'Moderator koʻrib chiqmoqda', 'Odatda 24 soat ichida', 'Natija', 'Moderator qarori shu yerda koʻrinadi' qoʻshildi; 'Shikoyatingiz allaqachon yuborilgan' tarjimasi "Жалоба уже отправлена" ga oʻzgardi.
- "Yuborish" tugmasidagi `send` ikonkasi foydalanuvchi soʻroviga koʻra olib tashlandi.

**Testlar:** `report_test.dart` SH6 bosqichlarini tekshiradi va X orqali yopadi (aylanuvchi halqa tufayli `pumpAndSettle` oʻrniga sanab pump qilinadi). `flutter analyze` toza; `flutter test` — 110 ta oʻtdi, faqat eski `auth_flow_test.dart` yiqiladi.

### 12. 2026-10-30 — xatoliklar Telegramga

Ilovadagi har qanday xatolik endi dasturchilar chatiga tushadi: qaysi sahifa, nima boʻlgan, stack, versiya va qurilma.

- **Server:** `functions/src/errors.ts` (sof funksiyalar: `parseErrorReport`, `errorMessage`, `trimStack`, `errorRateDay`) + `topildiLogError` (`onCall`, `index.ts`). Ilovada bot tokeni yoʻq — hamma narsa callable orqali oʻtadi. Xabar HTML: 🐞 sarlavha (platforma · versiya · debug), **Sahifa**, **Amal**, **Xabar**, **Qayerda** (tur · qurilma · til), **Kim** (uid), **Vaqt**, soʻng `<pre>` ichida stack (14 qator, qolgani "… +N"). Telegram limiti uchun 3500 belgida kesiladi, barcha matn escape qilinadi.
- **Chat:** `TELEGRAM_ERRORS_CHAT_ID` (`functions/.env`, hozircha boʻsh → `TELEGRAM_ADMIN_CHAT_ID` ga tushadi). Alohida chat/guruh ochib id sini shu yerga yozish mumkin.
- **Oqim nazorati:** kuniga `maxErrorsPerDay = 200` (hisoblagich `topildi_error_rate/{sana}`, faqat funksiya yozadi — rules kerak emas); ilovada bitta xatolik 10 daqiqada bir marta, bitta sessiyada koʻpi bilan 30 ta (`ErrorThrottle`, `errorSignature` raqamlarni `#` ga almashtiradi, shuning uchun "Listing l3 not found" va "l9" bitta xatolik hisoblanadi).
- **Ilova:** `lib/core/error/error_reporter.dart` — `TErrorReporter.instance.install()` `FlutterError.onError` va `PlatformDispatcher.onError` ni ushlaydi, `main.dart` esa butun ilovani `runZonedGuarded` ichiga oldi (`kind: flutter / platform / zone / manual`). Sahifa `app.dart` da router listeneridan olinadi. Versiya va qurilma uchun yangi paketlar: `package_info_plus`, `device_info_plus`.
- **Debug:** debug buildda yuborilmaydi (konsolda koʻrinadi); kerak boʻlsa `flutter run --dart-define=ERROR_REPORT_DEBUG=true`.
- **Qoʻlda xabar berish:** `TErrorReporter.instance.report(e, s, action: 'Shikoyat yuborish')` — ilova yiqilmagan, lekin bilish kerak boʻlgan joylar uchun.
- **Deploy qilindi (2026-10-30):** `topildiLogError` yaratildi, qolgan funksiyalar yangilandi. **Qolgani:** xohlasa alohida chat ochib `TELEGRAM_ERRORS_CHAT_ID` ga id sini yozish (hozir boʻsh → moderator chatiga tushadi) va ilovaning yangi buildi — TestFlight dagi `1.0.0 (1)` da bu kod yoʻq.

**Testlar:** `functions/src/test/errors.test.ts` — 7 ta (parse, uid, stack kesish, HTML escape, kun kaliti); `test/core/error_reporter_test.dart` — 6 ta (signature va throttle). `functions` jami 56 ta, `flutter analyze` toza.

### 13. 2026-10-30 — birinchi TestFlight buildi

Ilova birinchi marta TestFlight ga chiqdi: `Topildi`, `1.0.0 (1)`, bundle `com.topildi.topildi`, team `7DA9YV7633`.

**Qurish tartibi** (keyingi safar uchun):
1. `pubspec.yaml` da build raqamini oshirish (`1.0.0+1` → `+2`) — App Store Connect bir raqamni ikki marta qabul qilmaydi.
2. Tozalash (4.1-boʻlimdagi `objective_c` muammosi uchun majburiy):
 `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* .dart_tool/hooks_runner build/native_assets && flutter clean && flutter pub get`
3. `flutter build ipa --release` → `build/ios/archive/Runner.xcarchive` (va imzo boʻlsa `build/ios/ipa/*.ipa`).
4. `open build/ios/archive/Runner.xcarchive` → Organizer → **Distribute App ▸ App Store Connect ▸ Upload** (TestFlight Internal Only). Alohida "TestFlight ga yuborish" kanali yoʻq — TestFlight App Store Connect ichidagi tab, yuklash App Store ga chiqarish degani emas.

**Yoʻlda chiqqan toʻsiqlar va yechimlari:**
- `Unable to process request - PLA Update available` → developer.apple.com/account da yangilangan Program License Agreement ni hisob egasi qabul qilishi kerak. Shu sabab `flutter build ipa` ning eksport bosqichi ham yiqilgan edi ("No signing certificate iOS Distribution found" — sertifikat shartnomasiz berilmaydi).
- `STATE_ERROR.APP_CREATE.PLATFORM_NOT_ALLOWED_DUE_TO_CONTRACT_STATE` → App Store Connect → **Business** → *Paid Apps Agreement* da "View and Agree to Terms". Ilova bepul boʻlsa ham shart. Shundan keyin **Apps → + → New App** bilan yozuv qoʻlda yaratildi.
- `Upload Symbols Failed … dSYM for objective_c.framework` → faqat ogohlantirish, yuklash oʻtadi; oʻsha freymvork ichidagi crash hisoboti simvolsiz koʻrinadi.
- Export compliance: "What type of encryption algorithms…" → **None of the algorithms mentioned above** (ilova faqat HTTPS/TLS ishlatadi, oʻz kriptosi yoʻq). Har safar soʻralmasligi uchun `Info.plist` ga `ITSAppUsesNonExemptEncryption = NO` qoʻshish mumkin — **hali qoʻshilmagan**.
- Tester TestFlight da ilovani koʻrmasa: qurilmadagi Apple ID (Sozlamalar → Media va xaridlar) taklif yuborilgan email bilan bir xil boʻlishi, ichki tester esa avval App Store Connect taklifini qabul qilgan boʻlishi kerak. Taklif xatidagi **View in TestFlight** → **Accept** → **Install**. Ilova iOS 15.0+ talab qiladi.
- Deploy da `Quota exceeded for total allowable CPU per project per region` (Cloud Run, us-central1, loyiha FoodZeen bilan umumiy): yangilanmagan funksiyalar eski revision bilan ishlayveradi, 5–10 daqiqadan keyin faqat oʻshalarni qayta deploy qilish kifoya. Takrorlansa — Cloud Run Admin API kvotasini oshirish kerak.

### 14. 2026-10-30 — tungi rejim "OLED qora" (D2)

Qorongʻi tema eski "Koʻk tun" (D1) palitrasidan **OLED qora** ga oʻtkazildi (topshiriq: `32-tungi-rejim-oled`). Yorugʻ tema tegilmadi, splash (brend ekrani) ham oʻzgarmadi.

**Tokenlar** (`lib/core/theme/topildi_theme.dart`):
- `_darkScheme`: `surface` #000000, karta/sheet/appbar (`surfaceContainerLowest`) #111214, `surfaceContainerHigh` #17181b, `outline`/`outlineVariant` #26282d, `onSurface` #f2f4f8, `onSurfaceVariant` #8e95a3, `primary` #4d7fff, `primaryContainer` #14234a / #b9cdff, `error` #ff6b5e / #2a1211.
- `TopildiColors` ga yangi tokenlar: `primaryFill` (#3a6af0 — toʻldirilgan tugma, FAB, `Switch`, mening pufakcham; oq matn bilan 4.7:1), `surfaceGlow` (#0a1430), `onSurfaceSecondary`, `onSurfaceMuted` (#5f6672), `accentDot`, `glassFill`, `scrim`.
- Qorongʻi temada **yashil yoʻq**: `found`/`success` brend koʻki (#4d7fff / #14234a), `lost` #ff9f6e / #2a1a12, `warning` #f2c46b / #2a2210.
- `_build` ga `FilledButton` fon rangi, `floatingActionButtonTheme`, `switchTheme` (hammasi `primaryFill`) qoʻshildi. Profildagi `CupertinoSwitch` ham `primaryFill`.

**Qolgan joylar:** `TGlass._dark` (shisha `rgba(22,23,26,·)`, oq ramkalar, qora soyalar), `TSurfaces._dark` (neytral qora yuzalar), hamda widgetlardagi eski D1 hex qiymatlari "Eski → yangi" jadvali boʻyicha almashtirildi (chat, onboarding, claims, create, loader, sign-in, ghost karta, xarita nuqtalari). Koʻk soyalar qorongʻi temada qora soyaga aylantirildi (chat pufakchasi, `create_preview_card`). Profil sarlavhasi qorongʻi temada `primaryContainer` oʻrniga `surfaceGlow`.

**Ikkinchi oʻtish — ekranma-ekran koʻrib chiqish.** Simulyatorda (iPhone 15 Pro, qorongʻi) aylanib chiqildi: Lenta, Eʼlon + pull-down menyu, Shikoyat sheeti, Yangi eʼlon 1–3 qadam (xato holati bilan), Yashirin belgi sheeti, Koʻrib chiqish, Bildirishnomalar, Soʻrovlar (boʻsh), Chatlar (boʻsh), Profil, "Nimadir xato ketdi". Chat, Soʻrovlar (toʻliq), tasdiq dialogi, bloklash sheeti va Mening eʼlonlarim test muhitidagi mock maʼlumot bilan vaqtinchalik golden orqali olindi (keyin oʻchirildi, repoda qolmadi).

Topilgan va tuzatilgan kamchiliklar:
- Koʻp toʻldirilgan koʻk yuzalar hali `cs.primary` (#4d7fff) edi — oq matn bilan atigi 3.6:1. `primaryFill` ga oʻtkazildi: eʼlondagi asosiy tugma va soʻrovlar soni belgisi, `TSheetButton`, `TButton` ning yuklanish holati, tasdiq dialogidagi tugma, shikoyat sheetidagi qadam doiralari, Koʻrib chiqishdagi qadam doiralari va surish yoʻlagi, Yangi eʼlon tugmalari va tanlangan chiplar, "Kamera" plitkasi, Mening eʼlonlarimdagi "Eʼlon berish".
- Shikoyat sheetidagi oʻchiq "Yuborish" tugmasi oʻqilmas edi (butun tugma `Opacity(0.45)` — matn 1.5:1). Endi fon sahifa ustida 45% ga tushadi, matn esa 75% da qoladi (≈5.5:1).
- Qorongʻi temada qolgan **koʻk soyalar** olib tashlandi: `context.primaryGlow(opacity)` yordamchisi qoʻshildi (qorongʻida `rgba(0,0,0,0.4)`), chat pufakchasi va `create_preview_card` esa alohida tuzatildi.
- Profil sarlavhasi `primaryContainer` oʻrniga `surfaceGlow` (dizayndagidek deyarli qora).
- Xaritadagi "Topilgan" nuqtasi hali yashil edi (#4cbf85) — koʻk qilindi.

**Tekshirildi:** `flutter analyze` toza; `flutter test` — 116 oʻtdi, faqat eski `auth_flow_test.dart` yiqiladi (5-boʻlimda yozilgan, bu ishga aloqasi yoʻq); yorugʻ ↔ qorongʻi almashuvi ilovani qayta ishga tushirmasdan ishlaydi.

**Qilinmadi:** Eʼlon joylandi, Buyum qaytdi, Onboarding, Kirish, Xarita va Filtr sheeti qorongʻi rejimda koʻzdan kechirilmadi — ularda faqat kod boʻyicha eski palitra va koʻk soya qolmagani tekshirildi. Eʼlon joylash oxirigacha bajarilmadi (haqiqiy maʼlumot yaratmaslik uchun).

> `ios/Podfile.lock` ham oʻzgardi: `flutter build ios` paytida `device_info_plus` va `package_info_plus` podlari lockga qoʻshildi (temaga aloqasi yoʻq).

### Maxfiylik qoidalari (saqlanadi)

- **Telefon raqami** Firestore'ga hech qachon yozilmaydi — na eʼlonda, na so'rovda, na chatda.
- **Koordinatalar** yozishdan oldin ~300 m aniqlikkacha yaxlitlanadi.
- **Yashirin belgi** faqat `topildi_listings/{id}/private/secret` da, uni faqat muallif o'qiydi.
- **Rasmlar** (eʼlon, avatar, dalil) EXIF/GPS'siz yuklanadi.
- **Chat** faqat so'rov qabul qilingandan keyin ochiladi va faqat ikki aʼzoga ko'rinadi.

---

## ⏳ Qilinishi kerak

### 0. Hozir

- **Hisobni o'chirish (2026-10-30).** Profil → "Profilni tahrirlash" → pastda qizil "Hisobni oʻchirish" → tasdiq → `topildiDeleteAccount` (`functions/src/account.ts`). O'chiriladi: muallifning eʼlonlari (`private/secret` bilan), u yuborgan va uning eʼlonlariga kelgan so'rovlar, u aʼzo bo'lgan chatlar (xabarlar bilan, ikkala tomon uchun), `topildi_users/{uid}` (devices, notifications), Storage: `topildi/uploads/{uid}/`, `topildi/users/{uid}/`, eʼlon va so'rov papkalari. **Auth foydalanuvchisi** faqat FoodZeen'da `users/{uid}` (yoki `recipes`) bo'lmasa o'chiriladi — aks holda sessiyalar bekor qilinadi (loyiha umumiy, Telegram kirish raqam bo'yicha bir xil uid'ni ishlatadi). Ilovada: avval push tokeni o'chiriladi, server xato bersa push qaytib yoqiladi va foydalanuvchi chiqmaydi. **Deploy:** `cd functions && npm run deploy`.
- **Shikoyat va bloklash (2026-10-30)** — kod, rules va functions deploy qilingan (8- va 9-bo'lim). Chatdan shikoyat → Telegramga xabar va moderator tugmalari qurilmada tekshirildi. Qolgani: ilovaning yangi build'i (qayta shikoyat qilish uchun), 3 ta shikoyat → eʼlon lentadan yo'qolishini sinash, bloklash → xabar yuborib bo'lmasligini sinash.

0. **Chat ekrani commit qilinmagan.** Unga qo'shimcha ravishda `dart format` 80 ustun bilan 8 ta chat faylini bexosdan qayta formatlagan (`chat_mock_datasource`, `firestore_chat_datasource`, `chat_firestore`, `chat_repository_impl`, `entities/chat.dart`, `chat_list_cubit`, `chat_list_page`, `success_page`) — faqat formatlash, mantiq o'zgarmagan. Commit'dan oldin `git checkout` bilan qaytarish kerak; `ru.dart` va `chat_cubit.dart` da haqiqiy o'zgarishlar ham bor — ularni qaytarib, o'zgarishlarni qayta qo'llash. Loyiha 120 ustunda yozilgan: `dart format` ni papkaga emas, faqat o'zgargan faylga ishlatish.
1. **`storage.rules` deploy** (agar hali qilinmagan bo'lsa): `npx -y firebase-tools@15 deploy --only storage --project foodai-73d66`. Busiz rasmli eʼlon joylash xato beradi. Production deploy agent uchun bloklangan — egasi qiladi.
2. Rasmli eʼlonni haqiqiy qurilmada joylab ko'rish. Dalil rasmli so'rovni ham sinash: u hali Firestore'ni o'qiydigan eski Storage qoidasiga (`topildi/claims/{id}/proof.jpg`) tayanadi — xato bersa, uni ham `uploads` usuliga o'tkazish.
3. **So'rovni bekor qilish kutishi** — qaror kutilmoqda: hozir 3 kun; tavsiya 24 soat (eslatma bilan bir vaqtda) yoki "muallif ko'rmagan bo'lsa darhol" (yangi "ko'rildi" maydoni kerak). O'zgartirish: `ClaimTarget.cancelAfter` + `firestore.rules` (`duration.value`) + rules deploy.

### 1. Sinov (eng avval)

1. Firebase konsolida `topildi_chats` indeksi **Enabled** bo'lganini tekshirish.
2. Konsolga ikkinchi test raqam qo'shish (Authentication → Phone → test numbers).
3. Simulatorda ikki akkaunt bilan:
   - Topilgan eʼlon → "Bu meniki" (dalil rasm bilan) → Profil'da qizil belgi → qabul → chat, real vaqtda xabar, Chatlar belgisi, ✓✓ → "Qaytarildi" → Success.
   - Yo'qolgan eʼlon → "Men topdim" → qabul → chat → "Qaytarildi" (topgan odam bosadi, eʼlon yopiladi).
   - Rad etish va 3 urinish chegarasi.
4. Konsolda: claim/chat hujjatlarida telefon yo'q; Storage'dagi dalil rasmlar EXIF'siz.
5. 1-bosqichdan qolgan sinovlar: profil saqlash, filtrlar, o'chirish, chiqish.
6. 2026-10-28 ishlari haqiqiy qurilmada: eʼlonni tahrirlash (rasm qo'shish/olib tashlash, yashirin belgi bloki), so'rovni bekor qilish, eslatma push'i (24 soatdan keyin), loading kapsula, yangi ikonka va splash (Android ham), Bildirishnomalar'dagi "Yoqish" kartasi.

### 2. Push bildirishnomalarni ishga tushirish

`topildi` functions deploy qilingan (2026-10-28). Deploy uchun `cd functions && npm run deploy` ishlatiladi — global `firebase` CLI eski Node bilan qurilgan va funksiyalarni yuklay olmaydi.

**Aniqlandi (2026-10-31): push kelmasligining sababi — production APNs kaliti yo'q.**
Functions loglarida (`npx firebase functions:log --project foodai-73d66`) har bir hodisa uchun
`{"message":"push failed","code":"messaging/third-party-auth-error"}` chiqadi — bu FCM APNs'ga
ulana olmagani. Firebase Console → Cloud Messaging → Apple app configuration da
`topildi (ios)` uchun faqat **Development** APNs auth key turibdi
(Key ID `7B957SA98Y`, Team ID `7DA9YV7633`), "No production APNs auth key".
Team ID va bundle ID (`com.topildi.topildi`) Xcode loyihasidagi `DEVELOPMENT_TEAM` bilan mos —
demak kalitning o'zi to'g'ri, faqat production uyasi bo'sh. 2026-10-30 dagi sinovlar
TestFlight buildida bo'lgani uchun tokenlar production APNs'ga tegishli va kalit topilmagan.

Qolgan hamma bo'g'in ishlayapti: triggerlar ishga tushadi, `notifications` yoziladi
(demak Bildirishnomalar sahifasi to'ladi), qurilma tokeni
`topildi_users/{uid}/devices/{token}` ga saqlanadi. Faqat APNs'ga topshirish bosqichi yiqiladi.

**Haqiqiy sabab (2026-10-31): kalit faqat Sandbox uchun yaratilgan.**
`.p8` production uyasiga ham yuklandi, lekin push baribir kelmadi
(06:51 da yana `third-party-auth-error`). Kalit APNs'da to'g'ridan-to'g'ri sinab ko'rildi
(ES256 JWT + soxta device token; Apple avval JWT'ni tekshiradi):

| Kalit | `api.push.apple.com` (prod) | `api.sandbox.push.apple.com` |
|---|---|---|
| `7B957SA98Y` | 403 `BadEnvironmentKeyInToken` | 400 `BadDeviceToken` |
| `GUTVJ6ATF8` | 403 `BadEnvironmentKeyInToken` | 400 `BadDeviceToken` |
| `4RATX4YVY7` | 403 `InvalidProviderToken` | 403 `InvalidProviderToken` |
| `V2YY7GCVJY` | 403 `InvalidProviderToken` | 403 `InvalidProviderToken` |

Sandbox'dagi `BadDeviceToken` — kalit **qabul qilindi**, faqat soxta token rad etildi.
Production'dagi `BadEnvironmentKeyInToken` — kalit production muhitiga yaroqsiz.
Apple endi APNs kalitini yaratishda muhit tanlatadi (Sandbox / Production / ikkalasi);
bu ikkala kalit ham **Sandbox** qilib yaratilgan. Oxirgi ikkisi bu jamoaning APNs kaliti emas.
TestFlight buildi production APNs'ga ulanadi — shuning uchun hech qachon ishlamagan.

**✅ Hal qilindi (2026-10-31).** Apple'da *Sandbox & Production* muhiti bilan yangi APNs
kaliti yaratildi — `GJG9MK5C63` (`~/Downloads/AuthKey_GJG9MK5C63.p8`) — va Firebase'dagi
ikkala uyaga ham qo'yildi. Tekshiruv ikkala muhitda ham `400 BadDeviceToken` qaytardi,
yaʼni kalit qabul qilinadi. Shundan keyin `topildiOnMessageCreated` 07:00:59 da (UTC)
`push failed` ogohlantirishisiz o'tdi — push yetib bordi.

Kalitni sinash skripti: ES256 JWT tuzib, soxta device token bilan
`api.push.apple.com` va `api.sandbox.push.apple.com` ga so'rov yuboradi.
Javoblarning maʼnosi: `BadDeviceToken` — kalit yaroqli;
`BadEnvironmentKeyInToken` — kalit bu muhitga yaratilmagan;
`InvalidProviderToken` — kalit bu jamoaniki emas yoki APNs yoqilmagan.

Eski qurilma tokenlari o'chirilmagan (`third-party-auth-error` ∈ `staleTokenErrors` emas),
shuning uchun ilovani qayta o'rnatish shart emas.

1. ~~**O'sha `.p8` faylni production uyasiga ham yuklash**~~ (Console'dagi "No production APNs auth
   key" qatoridagi *Upload*). Bitta `.p8` auth key ikkala muhitga ham yaroqli — sertifikatdan
   farqi shu; Firebase'ning yangi konsoli shunchaki ikkita uya ko'rsatadi.
2. `ios/Runner/Runner.entitlements` da `aps-environment` = `development`, va uchala
   konfiguratsiya (Debug / Release / Profile) shu bitta faylni ishlatadi
   (`CODE_SIGN_ENTITLEMENTS`). O'zgartirilmadi — kalit tuzatilgach push ishladi, yaʼni
   Xcode arxivlashda bu qiymatni distribution profildan olib almashtirar ekan.
   Agar kelajakda dev buildda ishlab TestFlight'da ishlamasa, shu yerga qaytish kerak:
   alohida `RunnerRelease.entitlements` qilib, Release konfiguratsiyasiga ulash.
2. Haqiqiy iPhone'da ikki akkaunt bilan sinov (simulatorda push to'liq ishlamaydi): har bir hodisa, push bosilganda to'g'ri ekran (ilova yopiq / fonda / ochiq), chiqqandan keyin push kelmasligi, til almashganda push tili.
6. Keyin: ilova ikonkasidagi badge soni (hozir yuborilmaydi), o'xshash eʼlon topilganda bildirishnoma.

### 2.1. "Egasiga qaytdi" tasmasi (2026-10-31)

Lentaning tepasida, chiplar ostida turadigan gorizontal tasma: qaytarilgan
buyumlar ijtimoiy isbot sifatida. **Kod tayyor, dizayn kutilmoqda.**

Qarorlar: kartochka **bosilmaydi** (qaytarilgan eʼlonda ochiladigan sahifa
yo'q), **ism ko'rsatilmaydi** (`ReturnedItem` da muallif maydoni umuman yo'q),
`documents` toifasi chiqarib tashlanadi (qaytarilgan pasport qayta eʼlon
qilinmaydi), va eʼlon soni **3 tadan kam bo'lsa tasma butunlay chizilmaydi**
(`FeedState.minReturned`) — bo'sh devor ilovaga qarshi dalil bo'ladi.

Qo'shilgan: `ReturnedItem` entitysi, `ListingRemoteDataSource.fetchReturned`,
`ListingRepository.getReturned` (bloklanganlar va hujjatlar shu yerda
filtrlanadi), `GetReturnedItems`, `FeedState.returned` / `showReturned`,
`ReturnedStrip` widgeti, `TDate.ago`.

`returnedAt` eʼlon hujjatida saqlanmaydi — `updatedAt` dan o'qiladi
(`listingFromFirestore`), chunki status o'zgarishi yopilgan eʼlonga
yoziladigan oxirgi yozuv. Yangi maydon ham, rules o'zgarishi ham kerak
bo'lmadi.

**Indeks deploy qilindi (2026-10-31):** `status` ASC + `updatedAt` DESC,
`npx -y firebase-tools@15 deploy --only firestore:indexes --project foodai-73d66`.
Deploydan oldin tekshirildi: bazada faqat `topildi_*` indekslari bor
(FoodZeen'da kompozit indeks yo'q), shuning uchun o'chib ketadigan begona
indeks bo'lmadi — qo'shildi: 1, o'chirildi: 0, jami 8 ta.

**Dizayn keldi va qo'llandi (2026-10-31).** Brief:
`docs/design/returned-strip-prompt.md`; javob: `~/Downloads/topildi-egasiga-qaytdi.html`
va `TOPSHIRIQ-egasiga-qaytdi-lentasi.md`. Tanlangan shakl — **stories qatori**:
72px element, 58px doira rasm, 2px `primary` halqa, o'ng pastda `verified`
rozetkasi (ichida oq galochka, tashqarisi sahifa fonida — halqani kesadi),
ostida nom (labelMedium, 1 qator) va vaqt ("oldin" so'zisiz: "2 soat", "1 kun").
Sarlavha qatorida "Egasiga qaytdi · bu hafta {n}" (hisob faqat n ≥ 3 bo'lsa).

**✕ (yashirish) olib tashlandi (2026-10-31, egasining qarori).** Dizayner uni
o'z taklifi sifatida qo'shgan edi (brief'da yo'q edi), lekin zanjiri yomon
chiqdi: avval "Yashirildi / Qaytarish" snackbari o'chmay qoldi (✕ bosib 7 soniya
kutilganda ham turaverdi — taxminiy sabab: Flutter yordamchi texnologiya
yoqilganda `SnackBar` taymerini ishga tushirmaydi, simulatorni boshqaradigan
vosita esa accessibility orqali ishlaydi; **tasdiqlanmagan**, haqiqiy qurilmada
tekshirish kerak, chunki `TFeedback` ilovaning boshqa joylarida ham ishlatiladi).
Snackbar olib tashlangach, bitta tasodifiy bosish tasmani 30 kunga, qaytarish
yo'lisiz yo'qotadigan bo'ldi — sinov paytida uni simulyatorning `NSUserDefaults`
faylidan `flutter.proof_strip_hidden_at` kalitini qo'lda o'chirib tiklashga to'g'ri
keldi. Shuning uchun tugma butunlay olib tashlandi: tasma allaqachon kichkina,
3 tadan kam bo'lsa o'zi yashirinadi va kategoriya bilan torayadi — yashirish
tugmasi ortiqcha holat va ortiqcha xavf edi.

O'chirilganlar: `_HideButton`, `onHide`, `FeedState.stripHidden`,
`FeedCubit.hideStrip/showStrip/stripHiddenFor`, `FeedCubit` ning `KeyValueStore`
bog'liqligi, `StoreKeys.proofStripHiddenAt`, `home_page.dart` dagi `_hideStrip`.
`AnimatedSize` qoldi — endi u maʼlumot kelganda tasmani ochadi va kategoriya
tanlanganda 3 tadan kam qolsa yopadi.

Kategoriya chipi tanlansa tasma shu toifa bilan torayadi (`FeedState.visibleReturned`);
3 tadan kam qolsa yana yo'qoladi.

Ikki chekinish: `clothes` uchun loyihaning o'z ikonkasi (`Symbols.apparel_rounded`)
qoldirildi, topshiriqdagi `checkroom` emas — ikonkalar `category_ui.dart` dan
keladi va faqat tasma uchun boshqasini qo'yish ilovada nomuvofiqlik yaratadi.
Tasmaning tepa paddingi 14 emas, **6**: pinned chiplar sarlavhasi allaqachon
8 bilan tugaydi, grid esa 6 qo'shadi — ekranda dizayndagi 14/16 chiqadi.

Qurilmada tekshirildi (iPhone 15 Pro simulyatori, haqiqiy Firestore maʼlumoti):
yorug' va qorong'i tema, rasmli va rasmsiz elementlar, uzun nomlar.

**Ochiq savol:** 72px kenglikda nom ~9-10 belgidan keyin kesiladi
("Qora c…", "Ererererer…"). Eʼlon sarlavhasi 60 belgigacha bo'lishi mumkin,
shuning uchun ko'p nom o'qilmaydi. Variantlar: nomga 2 qator berish
(+~16pt balandlik) yoki nom o'rniga toifa nomini ko'rsatish. Hozircha
topshiriqdagidek 1 qator.

Testlar: `test/features/listing/returned_items_test.dart` (hujjatlar va
bloklangan muallif filtri, limit, offline), `feed_cubit_test.dart` (3 ta
chegara, kategoriya filtri, yashirishning saqlanishi va 30 kundan keyin
qaytishi), `finder_flow_test.dart` yangilandi — qaytarilgan eʼlon griddan
chiqib, tasmada paydo bo'lishi tekshiriladi. `home_layout_test` (360/393,
130% matn) tasma bilan birga o'tadi — bir marta 9px toshish bo'lgan, element
balandligi endi `TextScaler` dan hisoblanadi.

### 3. Bildirishnomalar sahifasi

Firestore'ga ulangan (yuqorida). Hozircha "o'xshash buyum topildi" va "eʼlon arxivlanadi" turlari yo'q.

### 4. Pul topish: eʼlonni tepaga ko'tarish (boost) — reja

Qarorlar: **Click va Payme ikkalasi**, tariflar **1 / 3 / 7 kun** (taxminan 10 000 / 20 000 / 35 000 so'm, narx serverda), merchant akkaunt **hali yo'q**. Asosiy oqim (eʼlon, "Bu meniki", chat) bepul qoladi. To'liq reja: `~/.claude/plans/ha-plan-qilib-ber-rustling-pike.md`.

- **Model:** `topildi_listings/{id}.boostedUntil` (faqat server yozadi; `validListing` kalitlariga qo'shiladi, muallifning update `affectedKeys` ga qo'shilmaydi); `topildi_boost_orders/{id}` — `{listingId, uid, plan, days, amount, provider, status, providerTxId, createdAt, paidAt}`, egasi o'qiydi, yozish faqat functions. Faollashtirish: `boostedUntil = max(hozir, joriy) + kunlar`, idempotent.
- **1-bosqich (to'lovsiz, hozir qilsa bo'ladi):** `functions/src/boost.ts` — `topildiBoostPlans`, `topildiCreateBoostOrder` (muallif va `active` tekshiruvi), umumiy `activateBoost` (+ push "Eʼloningiz tepaga koʻtarildi"), sinov uchun `topildiDevActivateBoost` (faqat `BOOST_DEV=true`). Ilova: `Listing.boostedUntil`; lentada ikkinchi so'rov (`type, status, city, boostedUntil > now`, limit 10) natijasi ro'yxat boshiga, indeks `(type, status, city, boostedUntil)`; yangi `lib/features/boost/` (repository + `BoostCubit` + glass sheet: tariflar, Click/Payme, "Toʻlash" → loading kapsula → `LinkLauncher` → buyurtma kuzatiladi); eʼlon sahifasida muallifga "Tepaga koʻtarish" / "Tepada · N kun qoldi", lenta kartasida "↑ Tepada", "Mening eʼlonlarim"da holat.
- **2-bosqich (merchant ochilgach):** `topildiClickWebhook` (Prepare/Complete, `sign_string` MD5 tekshiruvi) va `topildiPaymeWebhook` (JSON-RPC: Check/Create/Perform/Cancel/CheckTransaction/GetStatement, Basic auth, summa tiyinda, 12 soat timeout); sirlar `defineSecret` bilan; sandbox, so'ng prod.
- **Biznes tomondan kerak:** YaTT/MChJ, Click va Payme shartnomalari, ommaviy oferta, chek fiskalizatsiyasi (MXIK/IKPU kodi).
- **Boshqa daromad g'oyalari** (keyinroq): topuvchiga ixtiyoriy "rahmat" (komissiya bilan), tashkilotlar uchun B2B panel (metro, savdo markazi, universitet, taksi), QR stiker/brelok, kontekstli hamkor reklama. Qilinmaydi: asosiy oqimni pullik qilish, raqamni pulga ochish, erta banner reklama.

### 4.1. iOS build eslatmalari

- `objective_c` (`path_provider_foundation` orqali) native assets ishlatadi. Xcode'dan to'g'ridan-to'g'ri yoki eski kesh bilan yig'ilsa: simulyatorda `DOBJC_initializeApi … Failed to load`, qurilmada `objective_c.framework … invalid signature` (ad-hoc imzo, eski `_CodeSignature`).
- Yechim: `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*`, `flutter clean && flutter pub get`, so'ng `flutter run` (tavsiya) yoki Xcode → Clean Build Folder.
- **⚠️ Arxivlashdan oldin HAR SAFAR tozalash (2026-10-31).** App Store Connect
  yuklashni rad etdi: `Invalid executable … objective_c … references an
  unsupported platform in the arm64 slice … Simulator platforms aren't
  permitted` (kod 91169). Sabab: native assets freymvorklari bitta umumiy
  papkaga chiqadi — `build/native_assets/ios/` — va u **oxirgi build qaysi
  platforma uchun bo'lsa, o'shaniki bo'lib qoladi**. Simulatorda ishlagandan
  keyin arxivlansa, Xcode Dart kodini qurilma uchun qayta quradi, lekin
  `objective_c.framework` ni o'sha papkadan tekshirmasdan ko'chiradi.
  Apple Silicon'da ikkalasi ham `arm64`, shuning uchun `lipo` farqni
  ko'rsatmaydi — farq `LC_BUILD_VERSION` dagi platformada:
  `IOSSIMULATOR` ↔ `IOS`.

  Tozalash (arxivdan oldin, simulatorda ishlagan bo'lsangiz — majburiy):

  ```
  rm -rf .dart_tool/hooks_runner build/native_assets
  flutter clean && flutter pub get
  ```

  Tekshirish (arxivlashdan oldin `flutter build ios --release --no-codesign`
  qilib, keyin):

  ```
  vtool -show-build-version build/ios/iphoneos/Runner.app/Frameworks/objective_c.framework/objective_c
  ```

  `platform IOS` bo'lishi kerak. 2026-10-31 da tozalangandan keyin `.app`
  ichidagi 42 ta freymvorkning hammasi tekshirildi: `IOS` yoki
  `LC_VERSION_MIN_IPHONEOS` (ikkalasi ham qurilma), birortasi ham simulator emas.

- Deploy buyruqlari: Cloud Functions — `cd functions && npm run deploy` (global `firebase` CLI eski Node bilan qurilgan, funksiyalarni yuklay olmaydi); Firestore — `firebase deploy --only firestore:rules,firestore:indexes --project foodai-73d66`; Storage — `npx -y firebase-tools@15 deploy --only storage --project foodai-73d66`.

### 5. Mayda kamchiliklar

- (SMS kirish olib tashlangan bo'lsa, bu band endi kerak emas) SMS kod xato matnlari dizayn bilan bir xil emas: Firebase "Kod notoʻgʻri. Qayta tekshiring" / "Kod eskirdi. Yangisini oling", dizayn — "Qayta kiriting" / "Kod eskirgan. Yangisini soʻrang"; kod eskirganda "Qayta yuborish" darhol faollashishi kerak.
- So'rov bekor qilinganda muallifning bildirishnomalar ro'yxatida eski "Yangi so'rov" yozuvi qoladi (bosilsa, so'rov yo'q).
- "So'rov kelgan bo'lsa yashirin belgi o'zgarmaydi" qoidasini faqat ilova tekshiradi; to'liq himoya uchun Cloud Function kerak.
- Tumanlar ro'yxati xotiradan tuzilgan (2022 dan keyingi yangi tumanlar yo'q) — rasmiy ro'yxat bilan solishtirish kerak.
- Lentada eʼlon ko'rinmadi (2026-10-29, aniqlanmagan): lenta faqat tanlangan hudud (standart Toshkent), tur tabi va davr bo'yicha so'raydi; boshqa hududda joylangan eʼlon Toshkent lentasida chiqmaydi. Agar sabab shu bo'lsa — joylagandan keyin lentani eʼlon hududi va turiga o'tkazish kerak.
- Toshkentdan tashqarida tuman markazlari yo'q: qo'lda tanlangan tumanli eʼlonga viloyat markazining nuqtasi yoziladi ("Aniqlash" bo'lsa — GPS katagi). Xarita yoqilsa, tuman markazlarini qo'shish kerak.
- Chat shikoyatining dalilida faqat sarlavha keldi, xabarlar yo'q (2026-10-30, aniqlanmagan). Agar o'sha chatda haqiqatan xabarlar bo'lgan bo'lsa, `chatEvidence` (`functions/src/moderate.ts`) ularni ololmagan — `senderId` / `text` / `createdAt` maydonlarini tekshirish kerak.
- `test/features/auth/auth_flow_test.dart` yiqiladi ("Nimadir topdingizmi?" topilmaydi). Toza `main` da ham yiqiladi, yaʼni shikoyat ishiga aloqasi yo'q.
- Eski ishlatilmay qolgan tarjimalar (`ru.dart`): masalan "Eʼlonni tahrirlash tez orada qoʻshiladi".
- Eʼlon sahifasidagi muallif uchun so'rovlar soni sahifa ochilganda yuklanadi (real vaqtda emas).
- Simulator uchun reCAPTCHA'ni o'chirish (`appVerificationDisabledForTesting`, faqat test raqamlar bilan) — taklif qilingan, qilinmagan.

### 6. Keyinroq

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
- Rules o'zgarganda: avval `firebase deploy --only firestore,storage --project foodai-73d66 --dry-run`, deploy faqat ruxsat bilan. FoodZeen qoidalariga tegilmaydi

If this comes back after you switch between a real iPhone and the simulator, run the same cleanup again:
rm -rf .dart_tool/hooks_runner build/native_assets && flutter clean && flutter pub get