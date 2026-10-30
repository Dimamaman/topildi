# Topildi — loyiha holati

> Oxirgi yangilanish: 2026-10-29

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

**Branchlar (2026-10-26):** hamma ish `main` ga birlashtirildi — PR #3 → `firebase-phase1` → `main` (fast-forward). Yangi ish `main` dan alohida branch'da boshlanadi.

**Tekshiruv (2026-10-29):** `flutter analyze` toza; `flutter test` — 103 ta test o'tadi; `functions`: `npm test` — 34 ta; `flutter build ios --simulator --debug` muvaffaqiyatli; Firestore rules, indekslar va `topildi` functions deploy qilingan.

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

### Maxfiylik qoidalari (saqlanadi)

- **Telefon raqami** Firestore'ga hech qachon yozilmaydi — na eʼlonda, na so'rovda, na chatda.
- **Koordinatalar** yozishdan oldin ~300 m aniqlikkacha yaxlitlanadi.
- **Yashirin belgi** faqat `topildi_listings/{id}/private/secret` da, uni faqat muallif o'qiydi.
- **Rasmlar** (eʼlon, avatar, dalil) EXIF/GPS'siz yuklanadi.
- **Chat** faqat so'rov qabul qilingandan keyin ochiladi va faqat ikki aʼzoga ko'rinadi.

---

## ⏳ Qilinishi kerak

### 0. Hozir

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

1. APNs `.p8` kalit Firebase'ga yuklanganini va Xcode'da **Push Notifications** yoqilganini tekshirish.
2. Haqiqiy iPhone'da ikki akkaunt bilan sinov (simulatorda push to'liq ishlamaydi): har bir hodisa, push bosilganda to'g'ri ekran (ilova yopiq / fonda / ochiq), chiqqandan keyin push kelmasligi, til almashganda push tili.
6. Keyin: ilova ikonkasidagi badge soni (hozir yuborilmaydi), o'xshash eʼlon topilganda bildirishnoma.

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
- Deploy buyruqlari: Cloud Functions — `cd functions && npm run deploy` (global `firebase` CLI eski Node bilan qurilgan, funksiyalarni yuklay olmaydi); Firestore — `firebase deploy --only firestore:rules,firestore:indexes --project foodai-73d66`; Storage — `npx -y firebase-tools@15 deploy --only storage --project foodai-73d66`.

### 5. Mayda kamchiliklar

- (SMS kirish olib tashlangan bo'lsa, bu band endi kerak emas) SMS kod xato matnlari dizayn bilan bir xil emas: Firebase "Kod notoʻgʻri. Qayta tekshiring" / "Kod eskirdi. Yangisini oling", dizayn — "Qayta kiriting" / "Kod eskirgan. Yangisini soʻrang"; kod eskirganda "Qayta yuborish" darhol faollashishi kerak.
- So'rov bekor qilinganda muallifning bildirishnomalar ro'yxatida eski "Yangi so'rov" yozuvi qoladi (bosilsa, so'rov yo'q).
- "So'rov kelgan bo'lsa yashirin belgi o'zgarmaydi" qoidasini faqat ilova tekshiradi; to'liq himoya uchun Cloud Function kerak.
- Tumanlar ro'yxati xotiradan tuzilgan (2022 dan keyingi yangi tumanlar yo'q) — rasmiy ro'yxat bilan solishtirish kerak.
- Lentada eʼlon ko'rinmadi (2026-10-29, aniqlanmagan): lenta faqat tanlangan hudud (standart Toshkent), tur tabi va davr bo'yicha so'raydi; boshqa hududda joylangan eʼlon Toshkent lentasida chiqmaydi. Agar sabab shu bo'lsa — joylagandan keyin lentani eʼlon hududi va turiga o'tkazish kerak.
- Toshkentdan tashqarida tuman markazlari yo'q: qo'lda tanlangan tumanli eʼlonga viloyat markazining nuqtasi yoziladi ("Aniqlash" bo'lsa — GPS katagi). Xarita yoqilsa, tuman markazlarini qo'shish kerak.
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