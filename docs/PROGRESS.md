# Topildi — loyiha holati

> Oxirgi yangilanish: 2026-10-25

Topildi — yo'qolgan va topilgan buyumlar uchun Flutter ilova.
- **Arxitektura**: Clean Architecture — `flutter_bloc`, `get_it` + `injectable` (`@prod` / `@test`), `fpdart`.
- **Interfeys**: o'zbek tilida (lotin).

## Hozirgi etap

**Firebase bilan real maʼlumotlarga o'tish — 1-bosqich (Auth + Lenta + Eʼlon).** Kod yozib bo'lingan, testlar o'tadi, iOS simulator uchun build tayyor.

Qolgan ishlar:
1. Firestore/Storage qoidalari (rules) va indekslarni `foodai-73d66` ga deploy qilish. Buyruq tayyor, faqat ruxsat kutilmoqda.
2. Firebase konsolida Phone va Google provayderlarini yoqish.
3. Simulatorda boshidan oxirigacha (end-to-end) tekshirish.
4. Commit qilish.

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

## 4. 2-bosqich — ⏳ rejada

Hozircha **mock** bo'lib qolganlar (real eʼlonlarda so'rovlar soni 0 ko'rinadi):
- so'rovlar ("Bu meniki");
- chat;
- bildirishnomalar.

Reja:
- `claims` va `chats` kolleksiyalari;
- so'rov qabul qilinganda chat ochadigan Cloud Function;
- FCM push bildirishnomalar;
- Android'ni sozlash (`google-services.json`, Gradle plagini, SHA-1/SHA-256).
