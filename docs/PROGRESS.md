# Topildi — loyiha holati

> Oxirgi yangilanish: 2026-10-26

Topildi — yo'qolgan va topilgan buyumlar uchun Flutter ilova.
- **Arxitektura**: Clean Architecture — `flutter_bloc`, `get_it` + `injectable` (`@prod` / `@test`), `fpdart`.
- **Interfeys**: o'zbek tilida (lotin).

## Hozirgi etap

**Firebase bilan real maʼlumotlarga o'tish — 1-bosqich (Auth + Lenta + Eʼlon).**

**Branchlar:**
- `firebase-phase1` — Firebase 1-bosqich (Mac'dagi sessiyada yozilgan).
- `claude/fervent-mendel-ka2vga` — `firebase-phase1` + quyidagi tuzatishlar; PR [#3](https://github.com/Dimamaman/topildi/pull/3) → `firebase-phase1`. Hali merge qilinmagan.
- `main` — dizayn ishlari (PR #1, #2 merge qilingan); Firebase hali `main` da yo'q.

**PR #3 dagilar:**
- iOS: reCAPTCHA'dan keyingi "Page Not Found" tuzatildi — `SceneDelegate.swift` URL'ni `Auth.auth().canHandle` ga uzatadi, `Info.plist` da `FlutterDeepLinkingEnabled = false`.
- Firebase xatolari logga chiqadi (`FirebaseAuth error: ...`, `Firebase error: plugin/code: ...`); debug build'da ekranda ham ko'rinadi.
- Xarita `Features.map` flagi bilan yashirilgan (pastda alohida bo'lim).
- Lenta 2 ustunli grid (`FeedGridCard`); "Mening eʼlonlarim" eski `FeedCard` da.
- Lenta bo'sh holati: glass ikonka + "+" ga strelka (`feed_empty_state.dart`).

**Firebase konsolida qilingan (2026-10-25/26):**
- Phone provider yoqilgan; test raqam `+998 90 660 13 14` → `123456`.
- SMS region policy'da O'zbekiston ruxsat etilgan.
- `firestore:rules` deploy qilingan (FoodZeen qoidalari bilan solishtirilgan — bir xil).
- `firestore:indexes` deploy qilingan (5 ta indeks; build bo'lishini kutish kerak edi).
- Simulatorda: raqam → reCAPTCHA → SMS kod → kirish **ishladi**.

**Qolgan ishlar:**
1. Indekslar "Enabled" bo'lgach Lentani tekshirish.
2. Storage qoidalarini deploy qilish — avval konsoldagi Storage Rules'ni repo'dagi `storage.rules` (FoodZeen: `users/{userId}/recipes/{allPaths=**}`) bilan solishtirish. Storage qoidasi Firestore'ni o'qiydi — CLI ruxsat so'rasa "Yes".
3. Simulatorda: profil saqlash, rasmli eʼlon joylash (Joylashuvim / Tumanni tanlash), filtrlar, Mening eʼlonlarim, o'chirish, "Qaytarildi", chiqish.
4. Konsolda: eʼlonda telefon va aniq koordinata yo'qligini, rasmlar EXIF'siz ekanini tekshirish.
5. PR #3 ni `firebase-phase1` ga, keyin `firebase-phase1` ni `main` ga merge qilish.

**Ochiq savollar / keyinroq:**
- Xato matnlari bir xil emas: Firebase "Kod notoʻgʻri. Qayta tekshiring" / "Kod eskirdi. Yangisini oling", dizayn — "Qayta kiriting" / "Kod eskirgan. Yangisini soʻrang"; kod eskirganda "Qayta yuborish" darhol faollashishi kerak.
- Haqiqiy iPhone'da reCAPTCHA'siz: APNs `.p8` kalitini Firebase'ga yuklash + Xcode'da Push Notifications va Background Modes → Remote notifications.
- Simulator uchun reCAPTCHA'ni o'chirish (`appVerificationDisabledForTesting`, faqat test raqamlar bilan) — taklif qilingan, qilinmagan.
- Telegram Gateway orqali kod yuborish — muhokama qilingan, hozircha faqat Firebase SMS.
- Eʼlonni tahrirlash oqimi yo'q ("tez orada" toast).

**Ish uslubi (oldingi sessiyadan):** foydalanuvchi bilan o'zbekcha gaplashiladi; dizayn topshiriqlari PDF + PNG (+ HTML) bilan keladi; har bir ekran real Inter va Material Symbols shriftlari bilan golden skrinshot qilinib dizayn bilan solishtiriladi (393, 375×667, 360; yorug'/qorong'i; 130% matn); matnlar `tr()` orqali, yangi matnga `ru.dart` da tarjima shart (`l10n_test`); ripple yo'q, bosiladigan joy ≥44.

---

## 1. Dizayn (iOS 26 uslubi) — ✅ tayyor

**Glass UI tizimi:**
- `GlassSurface` — blur, saturatsiya, chekka (rim) yorug'ligi va soya;
- `TGlass` tokenlari;
- glass header, glass sheet;
- pull-down menyu: `OverlayEntry` asosida, bosib-sudrab tanlash mumkin.

**Qayta ishlangan ekranlar:**
- Kirish, SMS kod;
- **Tanishib olaylik** (profil sozlash) — orbita avatar, emoji, rang. Familiya maydoni olib tashlangan;
- **Lenta (Home)** — skeleton yuklanish, tur tablari, karta teglari;
- **Mening eʼlonlarim** — tab almashganda Home'dagidek skeleton bilan qayta yuklanadi;
- **Filtrlar sheeti** — tanlangan kategoriya chiplarida galochka yo'q;
- **Hudud menyusi** — pull-down;
- **Bildirishnomalar**, **Chatlar ro'yxati**;
- **Profil** — yuklanish skeletoni;
- **Barcha dialoglar** — iOS 26 uslubidagi glass alert.

**Mock maʼlumotlar** ko'paytirilgan.

## 2. Lokalizatsiya — ✅ tayyor

**Tillar:**
- Oʻzbekcha (lotin);
- Ўзбекча (kirill) — lotindan avtomatik o'giriladi (`toUzbekCyrillic`);
- Русский — `lib/core/l10n/ru.dart` dagi lug'atdan.

**Qanday ishlaydi:**
- matnlar `tr('...')` ga o'raladi, kalit — matnning o'zi;
- til **Til** menyusida almashtiriladi, butun ilova darhol qayta chiziladi (`LanguageCubit`);
- sanalar tanlangan tilga mos formatlanadi.

`test/core/l10n_test.dart` barcha matnlarning tarjimasi borligini tekshiradi.

## 3. Firebase — 1-bosqich 🟡 deyarli tayyor

**Firebase loyihasi:** `foodai-73d66` (Blaze tarifi).
- Bu loyihadan **FoodZeen** ilovasi ham foydalanadi.
- Shuning uchun Topildi'ning barcha maʼlumotlari alohida nom ostida saqlanadi (`FirePaths`, `lib/core/di/firebase_module.dart`):
  - **Firestore**: `topildi_users/{uid}`, `topildi_listings/{id}`, `topildi_listings/{id}/private/secret`;
  - **Storage**: `topildi/listings/{id}/{n}.jpg`, `topildi/users/{uid}/avatar.jpg`.

**Platforma: faqat iOS.** Android ataylab qilinmagan. Android'da `DefaultFirebaseOptions` xato beradi.

### Qilingan ishlar

| Qism | Fayllar |
|---|---|
| Firebase'ni ulash | `lib/firebase_options.dart`, `ios/Runner/GoogleService-Info.plist`, `main.dart` da `Firebase.initializeApp` |
| iOS sozlamalari | deployment target 15.0, `Info.plist` da Google URL scheme'lar, Podfile'da **oldindan kompilyatsiya qilingan Firestore** (gRPC/BoringSSL'ni kompilyatsiya qilmaydi, build ~1 daqiqa, Mac qizimaydi) |
| DI | `firebase_module.dart` — `FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage`, `GoogleSignIn` (`@prod`) |
| Auth | `firebase_auth_repository.dart` — SMS kod (`+998…`) va Google orqali kirish; profil `topildi_users/{uid}` da; xato xabarlari o'zbekcha |
| Session | `session.dart` — `FirebaseSession` (`@prod`), `LocalSession` (`@test`) |
| Eʼlonlar | `listing_remote_datasource.dart` (interfeys), `firestore_listing_datasource.dart` (`@prod`), `listing_mock_datasource.dart` (`@test`) |
| Model | `listing_firestore.dart` — Firestore ↔ `ListingModel` |
| Rasmlar | `photo_compress.dart` — 1600px, sifat 82, **EXIF o'chiriladi**; `photoProvider()` lokal fayl va URL'ni ko'rsatadi |
| Xatolar | `firebase_failure.dart` — `FirebaseException` → `Failure` |
| Rules | `firestore.rules`, `storage.rules` — FoodZeen qoidalari **o'zgarishsiz** saqlangan, Topildi qoidalari qo'shilgan. Dry-run: ikkalasi ham xatosiz kompilyatsiya bo'ladi |
| Indekslar | `firestore.indexes.json` — lenta filtrlari va "Mening eʼlonlarim" uchun 5 ta composite indeks |

**Ishlaydigan funksiyalar:**
- kirish;
- profil saqlash (ism, avatar rasm, emoji yoki rang);
- lenta va filtrlar (tur, shahar, tuman, kategoriya, sana);
- eʼlon joylash (rasmlar bilan);
- eʼlon sahifasi, Mening eʼlonlarim;
- o'chirish, "Qaytarildi";
- chiqish (sign-out).

### Maxfiylik qoidalari (saqlanadi)
- **Telefon raqami** Firestore'ga hech qachon yozilmaydi.
- **Koordinatalar** yozishdan oldin ~300 m aniqlikkacha yaxlitlanadi.
- **Yashirin belgi** (`hiddenDetail`) faqat `private/secret` da turadi, uni faqat muallif o'qiy oladi.
- **Rasmlar** EXIF/GPS'siz yuklanadi.

### Tekshiruv holati
- `flutter analyze` — toza.
- `flutter test` — **72 ta test o'tadi**, shu jumladan `test/features/listing/listing_firestore_test.dart`.
- `flutter build ios --simulator --debug` — muvaffaqiyatli.
- Real Firebase bilan simulatorda hali **tekshirilmagan**.

### Keyingi qadamlar
1. **Deploy** (ruxsat bilan): `firebase deploy --only firestore,storage --project foodai-73d66`.
2. **Firebase konsolida** (egasi qiladi):
   - Authentication → **Phone** va **Google** provayderlarini yoqish;
   - test uchun telefon raqami qo'shish (masalan `+998 90 000 00 00` / `123456`).
3. **Simulatorda tekshirish:**
   - SMS va Google orqali kirish;
   - profil saqlash, rasmli eʼlon joylash;
   - lenta va filtrlar;
   - o'chirish, "Qaytarildi";
   - chiqish.
4. **Konsolda tekshirish:**
   - eʼlon hujjatida telefon va aniq koordinata yo'q;
   - Storage'dagi rasmlar EXIF'siz.
5. **Commit.**

## Xarita — ⏸ keyingi versiyaga qoldirilgan

Xarita bilan bog'liq hamma narsa vaqtincha **yashirilgan**, kod o'chirilmagan. Bitta flag boshqaradi: `Features.map` (`lib/core/config/features.dart`), standart holatda o'chiq.
- Pastki menyudagi **Xarita** tabi ko'rinmaydi (route va `MapPage` joyida, shell branch raqamlari o'zgarmagan).
- Eʼlon sahifasida **Xaritada** qatori ko'rinmaydi.
- Eʼlon joylash (3-qadam): xarita o'rniga **Joylashuvim** (GPS) va **Tumanni tanlash** (Toshkent tumanlari, taxminiy markaz koordinatalari bilan).

Qaytarish: `flutter run --dart-define=FEATURE_MAP=true` yoki `features.dart` da standart qiymatni `true` qilish.

## 4. 2-bosqich — so'rovlar va chat 🟡 deploy qilingan, simulatorda sinalmagan

**Qilingan (kod, 2026-10-26):** so'rovlar ("Bu meniki") va chat Firestore'ga o'tkazildi. Cloud Functions yo'q — chatni ilova yaratadi, xavfsizlikni rules taʼminlaydi.

| Qism | Fayllar |
|---|---|
| So'rovlar | `claim_remote_datasource.dart` (interfeys), `firestore_claim_datasource.dart` (`@prod`), `claim_mock_datasource.dart` (`@test`), `claim_firestore.dart` |
| Chat | `chat_remote_datasource.dart` (interfeys + `ChatNotes`), `firestore_chat_datasource.dart` (`@prod`), `chat_mock_datasource.dart` (`@test`), `chat_firestore.dart` |
| Real vaqt | `ChatListCubit` va `ChatCubit` stream'ga obuna (`WatchChats`, `WatchChat`, `MarkChatRead`) |
| O'qildi belgisi | `ChatThread.otherReadAt` / `seen()`; chat pufakchasida ✓ / ✓✓ |
| Rules | `firestore.rules` (claims, chats, messages, listing'ni chat orqali yopish), `storage.rules` (proof rasm), `firestore.indexes.json` (chats: `members` + `lastAt`). Dry-run: ikkalasi kompilyatsiya bo'ladi |

**Firestore modeli:**
- `topildi_claims/{listingId}_{uid}_{n}` — n = 1..3 urinish; yangi urinish faqat oldingisi rad etilgandan keyin. Javob va proof rasmni faqat so'rovchi va eʼlon muallifi o'qiydi.
- `topildi_chats/{claimId}` — muallif so'rovni qabul qilganda bitta batch'da yaratiladi. `members`, `finderId` (found → muallif, lost → so'rovchi), `unread.{uid}`, `readAt.{uid}`.
- `topildi_chats/{id}/messages/{mid}` — `text` yoki `returned`. "Mos keldi" va xavfsizlik eslatmasi saqlanmaydi, chat `createdAt` dan chiziladi.
- "Qaytarildi": finder chat'ni yopadi, eʼlonni `returned` qiladi (`returnedViaChat` orqali, lost eʼlonda ham) va o'z `returnedCount` ini +1 qiladi.

**Qolgan ishlar:**
1. ~~Deploy~~ — 2026-10-26 qilindi (rules + indekslar). Konsolda chats indeksi "Enabled" bo'lganini tekshirish.
2. Konsolga ikkinchi test raqam qo'shish; simulatorda ikki akkaunt bilan: eʼlon → "Bu meniki" (proof rasm bilan) → qabul → chat, real vaqtda xabar, badge, ✓✓ → "Qaytarildi" → Success. Lost eʼlon uchun ham.
3. Konsolda: claim/chat hujjatlarida telefon yo'q; proof rasm EXIF'siz.

**Keyinroq:**
- FCM push (APNs `.p8` + Cloud Function).
- Bildirishnomalar sahifasi hali mock.
- Android'ni sozlash (`google-services.json`, Gradle plagini, SHA-1/SHA-256).
