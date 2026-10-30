import '../../../core/l10n/app_language.dart';
import '../../../core/l10n/cyrillic.dart';

/// Where users write about their data, complaints and account deletion.
const legalTelegram = '@dimamamann';

enum LegalKind { terms, privacy }

class LegalSection {
  const LegalSection(this.title, this.body);

  final String title;

  /// Paragraphs; a line starting with "• " is drawn as a bullet.
  final List<String> body;
}

class LegalDocument {
  const LegalDocument({required this.title, required this.updated, required this.intro, required this.sections});

  final String title, updated, intro;
  final List<LegalSection> sections;

  LegalDocument _map(String Function(String) f) => LegalDocument(
    title: f(title),
    updated: f(updated),
    intro: f(intro),
    sections: [
      for (final s in sections) LegalSection(f(s.title), [for (final p in s.body) f(p)]),
    ],
  );
}

/// The document in [language]. The texts are long, so they live here rather
/// than in `tr()`: Russian is written out, Cyrillic is derived from Latin.
LegalDocument legalDocument(LegalKind kind, AppLanguage language) {
  final doc = switch ((kind, language)) {
    (LegalKind.terms, AppLanguage.ru) => _termsRu,
    (LegalKind.privacy, AppLanguage.ru) => _privacyRu,
    (LegalKind.terms, _) => _termsUz,
    (LegalKind.privacy, _) => _privacyUz,
  };
  final cyrillic = language == AppLanguage.uzCyrl;
  // Filled in after transliteration so the username stays in Latin.
  final contact = switch (language) {
    AppLanguage.uzLatn => 'Telegram’dagi $legalTelegram',
    AppLanguage.uzCyrl => 'Телеграмдаги $legalTelegram',
    AppLanguage.ru => 'Telegram $legalTelegram',
  };
  return doc._map((s) => (cyrillic ? toUzbekCyrillic(s) : s).replaceAll('{contact}', contact));
}

// ─── Foydalanish shartlari ───────────────────────────────────────────────

const _termsUz = LegalDocument(
  title: 'Foydalanish shartlari',
  updated: 'Oxirgi yangilanish: 30-oktabr 2026',
  intro:
      'Topildi — yoʻqolgan va topilgan buyumlarni egasiga qaytarishga yordam beradigan ilova. '
      'Ilovadan foydalanib, siz ushbu shartlarga va Maxfiylik siyosatiga rozilik bildirasiz. '
      'Agar rozi boʻlmasangiz, iltimos, ilovadan foydalanmang.',
  sections: [
    LegalSection('1. Hisob', [
      'Ilovaga Telegram orqali kirasiz. Ilovadan 16 yoshdan katta shaxslar foydalanishi mumkin.',
      '• Profilda oʻzingiz haqingizda toʻgʻri maʼlumot koʻrsating.',
      '• Hisobingiz orqali qilingan harakatlar uchun siz javobgarsiz. Telegram hisobingizni begonalarga bermang.',
      '• Boshqa odam nomidan hisob ochish taqiqlanadi.',
    ]),
    LegalSection('2. Eʼlon qoidalari', [
      'Eʼlon bersangiz, quyidagilarga amal qilasiz:',
      '• Faqat haqiqatan yoʻqolgan yoki topilgan buyum haqida yozing.',
      '• Rasm va tavsif shu buyumga tegishli boʻlsin. Boshqalarning rasmlarini ruxsatsiz ishlatmang.',
      '• Eʼlonda shaxsiy maʼlumotlarni koʻrsatmang: hujjat va karta raqamlari, telefon raqami, uy manzili. '
          'Hujjat rasmini joylasangiz, raqam va shaxsiy maʼlumotlarni yopib qoʻying.',
      '• Yashirin belgini faqat haqiqiy egasi biladigan qilib yozing va uni tavsifda oshkor qilmang.',
      '• Sotuv, reklama, qonun bilan taqiqlangan buyumlar (qurol, giyohvand moddalar va boshqalar) haqida eʼlon berish taqiqlanadi.',
      '• Bedarak yoʻqolgan odamlar haqida eʼlon bermang — bunday holatda darhol 102 raqamiga qoʻngʻiroq qiling.',
      '• Buyum egasiga qaytgach, eʼlonni “Qaytarildi” deb belgilang.',
    ]),
    LegalSection('3. Soʻrovlar va egalikni tasdiqlash', [
      'Topilgan buyumga egasi “Bu meniki”, yoʻqolgan buyumga topgan odam “Men topdim” soʻrovini yuboradi va yashirin belgini yozadi.',
      '• Bitta eʼlonga koʻpi bilan 3 marta soʻrov yuborish mumkin; yangisi faqat oldingisi rad etilgandan keyin.',
      '• 3 kun ichida javob berilmagan soʻrov avtomatik bekor qilinadi.',
      '• Soʻrovni qabul qilish yoki rad etishni eʼlon muallifi oʻzi hal qiladi. Topildi egalikni tekshirmaydi va kafolatlamaydi.',
      '• Oʻzingizga tegishli boʻlmagan buyumga soʻrov yuborish taqiqlanadi.',
    ]),
    LegalSection('4. Chat va uchrashuv', [
      'Soʻrov qabul qilingach, ilova ichida chat ochiladi. Telefon raqamingiz koʻrsatilmaydi.',
      '• Suhbatdoshingizni hurmat qiling: haqorat, tahdid va spam taqiqlanadi.',
      '• Uchrashuvni gavjum jamoat joyida, kunduzi belgilang.',
      '• Buyumni olishdan oldin oldindan pul oʻtkazmang.',
      '• Buyumni qaytarishni pul toʻlashga bogʻlab tahdid qilish yoki tovlamachilik taqiqlanadi.',
      '• Pasport kabi muhim hujjatni topsangiz, uni ichki ishlar organlariga ham topshirishingiz mumkin.',
    ]),
    LegalSection('5. Taqiqlangan harakatlar', [
      '• Firibgarlik, boshqa odamni aldash yoki uning nomidan harakat qilish.',
      '• Ilova ishiga xalaqit berish, uni buzishga urinish, maʼlumotlarni avtomatik yigʻish.',
      '• Boshqa foydalanuvchilarning shaxsiy maʼlumotlarini ularning roziligisiz tarqatish.',
      '• Oʻzbekiston Respublikasi qonunchiligini buzadigan har qanday harakat.',
    ]),
    LegalSection('6. Kontentga boʻlgan huquqlar', [
      'Siz joylagan rasm va matnlar sizniki boʻlib qoladi. Ularni joylab, Topildi’ga ularni ilovada saqlash, siqish va '
          'boshqa foydalanuvchilarga koʻrsatish uchun bepul, noeksklyuziv ruxsat berasiz. Eʼlonni oʻchirsangiz, bu ruxsat tugaydi.',
      'Topildi nomi, logotipi va dizayni ilova egalariga tegishli.',
    ]),
    LegalSection('7. Eʼlonlar nazorati', [
      'Ushbu shartlarni buzgan eʼlon, soʻrov yoki hisobni ogohlantirishsiz yashirish yoki oʻchirish huquqimiz bor. '
          'Qoidabuzarlik haqida {contact} orqali xabar bering.',
    ]),
    LegalSection('8. Javobgarlikning cheklanishi', [
      'Topildi buyum egalari va topgan odamlarni bogʻlaydigan platforma xolos.',
      '• Buyum topilishi yoki qaytarilishini kafolatlamaymiz.',
      '• Foydalanuvchilar joylagan maʼlumotlarning toʻgʻriligi va ular oʻrtasidagi kelishuvlar uchun javob bermaymiz.',
      '• Ilova “boricha” taqdim etiladi; uzilishlar va xatolar boʻlishi mumkin, ularni tez tuzatishga harakat qilamiz.',
    ]),
    LegalSection('9. Toʻlovlar', [
      'Hozirda ilovadan foydalanish bepul. Pullik xizmatlar paydo boʻlsa, ularning narxi va shartlari toʻlovdan oldin alohida koʻrsatiladi.',
    ]),
    LegalSection('10. Hisobni yopish', [
      'Istalgan vaqtda ilovadan foydalanishni toʻxtatishingiz mumkin. Hisobingiz va maʼlumotlaringizni oʻchirish uchun {contact} ga yozing.',
    ]),
    LegalSection('11. Shartlarning oʻzgarishi', [
      'Shartlarni vaqti-vaqti bilan yangilashimiz mumkin. Muhim oʻzgarishlar haqida ilovada xabar beramiz. '
          'Oʻzgarishdan keyin ilovadan foydalanishni davom ettirsangiz, yangi shartlarga rozi boʻlgan hisoblanasiz.',
    ]),
    LegalSection('12. Amaldagi qonunchilik', [
      'Ushbu shartlar Oʻzbekiston Respublikasi qonunchiligiga muvofiq tartibga solinadi. '
          'Nizolar avval muzokara yoʻli bilan, kelishilmasa — qonunda belgilangan tartibda sudda hal qilinadi.',
    ]),
    LegalSection('13. Aloqa', ['Savol va takliflar uchun: {contact}']),
  ],
);

const _termsRu = LegalDocument(
  title: 'Условия использования',
  updated: 'Последнее обновление: 30 октября 2026',
  intro:
      'Topildi — приложение, которое помогает вернуть потерянные и найденные вещи владельцам. '
      'Пользуясь приложением, вы соглашаетесь с этими условиями и Политикой конфиденциальности. '
      'Если вы не согласны, пожалуйста, не пользуйтесь приложением.',
  sections: [
    LegalSection('1. Аккаунт', [
      'Вы входите в приложение через Telegram. Пользоваться приложением могут лица старше 16 лет.',
      '• Указывайте в профиле достоверные данные о себе.',
      '• Вы отвечаете за действия, совершённые через ваш аккаунт. Не передавайте доступ к Telegram посторонним.',
      '• Запрещено создавать аккаунт от имени другого человека.',
    ]),
    LegalSection('2. Правила объявлений', [
      'Размещая объявление, вы соблюдаете следующие правила:',
      '• Пишите только о действительно потерянной или найденной вещи.',
      '• Фото и описание должны относиться к этой вещи. Не используйте чужие фото без разрешения.',
      '• Не указывайте в объявлении личные данные: номера документов и карт, телефон, домашний адрес. '
          'Если публикуете фото документа, закройте номера и личные данные.',
      '• Пишите тайный признак так, чтобы его знал только настоящий владелец, и не раскрывайте его в описании.',
      '• Запрещены объявления о продаже, реклама, а также вещи, запрещённые законом (оружие, наркотики и т. п.).',
      '• Не публикуйте объявления о пропавших людях — в таком случае сразу обратитесь в полицию (102).',
      '• Когда вещь вернулась к владельцу, отметьте объявление как «Возвращено».',
    ]),
    LegalSection('3. Запросы и подтверждение владельца', [
      'На найденную вещь владелец отправляет запрос «Это моё», на потерянную — нашедший отправляет «Я нашёл», указывая тайный признак.',
      '• На одно объявление можно отправить не более 3 запросов; новый — только после отклонения предыдущего.',
      '• Запрос без ответа в течение 3 дней отменяется автоматически.',
      '• Принять или отклонить запрос решает автор объявления. Topildi не проверяет и не гарантирует право собственности.',
      '• Запрещено отправлять запросы на чужие вещи.',
    ]),
    LegalSection('4. Чат и встреча', [
      'После принятия запроса в приложении открывается чат. Ваш номер телефона не показывается.',
      '• Уважайте собеседника: оскорбления, угрозы и спам запрещены.',
      '• Назначайте встречу в людном общественном месте и в дневное время.',
      '• Не переводите деньги заранее, до получения вещи.',
      '• Запрещено угрожать или вымогать деньги в обмен на возврат вещи.',
      '• Найденные важные документы, например паспорт, можно также сдать в органы внутренних дел.',
    ]),
    LegalSection('5. Запрещённые действия', [
      '• Мошенничество, обман других людей или действия от их имени.',
      '• Вмешательство в работу приложения, попытки взлома, автоматический сбор данных.',
      '• Распространение личных данных других пользователей без их согласия.',
      '• Любые действия, нарушающие законодательство Республики Узбекистан.',
    ]),
    LegalSection('6. Права на контент', [
      'Размещённые вами фото и тексты остаются вашими. Публикуя их, вы даёте Topildi бесплатное неисключительное разрешение '
          'хранить, сжимать и показывать их другим пользователям в приложении. Разрешение прекращается, когда вы удаляете объявление.',
      'Название, логотип и дизайн Topildi принадлежат владельцам приложения.',
    ]),
    LegalSection('7. Модерация', [
      'Мы вправе без предупреждения скрыть или удалить объявление, запрос или аккаунт, нарушающие эти условия. '
          'О нарушениях сообщайте: {contact}.',
    ]),
    LegalSection('8. Ограничение ответственности', [
      'Topildi — лишь платформа, которая связывает владельцев вещей и тех, кто их нашёл.',
      '• Мы не гарантируем, что вещь будет найдена или возвращена.',
      '• Мы не отвечаем за достоверность данных, размещённых пользователями, и за договорённости между ними.',
      '• Приложение предоставляется «как есть»; возможны сбои и ошибки, мы стараемся быстро их исправлять.',
    ]),
    LegalSection('9. Платежи', [
      'Сейчас приложение бесплатное. Если появятся платные услуги, их цена и условия будут показаны отдельно до оплаты.',
    ]),
    LegalSection('10. Закрытие аккаунта', [
      'Вы можете перестать пользоваться приложением в любой момент. Чтобы удалить аккаунт и данные, напишите: {contact}.',
    ]),
    LegalSection('11. Изменение условий', [
      'Мы можем время от времени обновлять условия. О важных изменениях сообщим в приложении. '
          'Продолжая пользоваться приложением после изменений, вы соглашаетесь с новыми условиями.',
    ]),
    LegalSection('12. Применимое право', [
      'Эти условия регулируются законодательством Республики Узбекистан. '
          'Споры решаются путём переговоров, а при недостижении согласия — в суде в установленном законом порядке.',
    ]),
    LegalSection('13. Контакты', ['Вопросы и предложения: {contact}']),
  ],
);

// ─── Maxfiylik siyosati ──────────────────────────────────────────────────

const _privacyUz = LegalDocument(
  title: 'Maxfiylik siyosati',
  updated: 'Oxirgi yangilanish: 30-oktabr 2026',
  intro:
      'Ushbu siyosat Topildi qanday maʼlumotlarni yigʻishi, ulardan nima uchun foydalanishi va ularni qanday himoya qilishini tushuntiradi. '
      'Shaxsga doir maʼlumotlar Oʻzbekiston Respublikasining “Shaxsga doir maʼlumotlar toʻgʻrisida”gi Qonuniga muvofiq qayta ishlanadi.',
  sections: [
    LegalSection('1. Qanday maʼlumotlarni yigʻamiz', [
      '• Kirish maʼlumotlari: Telegram orqali kirishda ulashgan telefon raqamingiz.',
      '• Profil: siz kiritgan ism va avatar.',
      '• Eʼlonlar: buyum turi, sarlavha, tavsif, rasmlar, joy (xaritadagi nuqta, shahar, tuman) va sana.',
      '• Yashirin belgi: buyumni faqat egasi biladigan belgi.',
      '• Soʻrovlar: “Bu meniki” yoki “Men topdim” javobingiz va ixtiyoriy dalil rasmi.',
      '• Chat xabarlari: soʻrov qabul qilingandan keyin ochilgan chatdagi xabarlar.',
      '• Qurilma: bildirishnomalar uchun qurilma tokeni. Til va mavzu sozlamalari faqat qurilmangizda saqlanadi.',
    ]),
    LegalSection('2. Qurilma ruxsatlari', [
      '• Joylashuv — faqat ruxsat bersangiz, eʼlon joyini tanlash va yaqindagi eʼlonlarni koʻrsatish uchun. Fonda kuzatilmaydi.',
      '• Kamera va galereya — faqat siz tanlagan rasmlar yuklanadi. Yuklashdan oldin rasm siqiladi va undagi metamaʼlumotlar '
          '(suratga olingan joy, qurilma modeli) oʻchiriladi.',
      '• Bildirishnomalar — yangi soʻrov, xabar va eslatmalar haqida xabar berish uchun.',
      'Bu ruxsatlarni istalgan vaqtda qurilma sozlamalarida bekor qilishingiz mumkin.',
    ]),
    LegalSection('3. Maʼlumotlardan qanday foydalanamiz', [
      '• Hisobga kirish va uni himoya qilish.',
      '• Eʼlonlarni koʻrsatish, qidirish va saralash.',
      '• Buyum egasi va topgan odamni bogʻlash, soʻrov va chatlarni yuritish.',
      '• Bildirishnomalar yuborish.',
      '• Firibgarlik va qoidabuzarliklarning oldini olish.',
      '• Ilova ishini tuzatish va yaxshilash.',
      'Maʼlumotlaringizni sotmaymiz va reklama maqsadida uchinchi shaxslarga bermaymiz.',
    ]),
    LegalSection('4. Boshqalar nimani koʻradi', [
      '• Ilovaga kirgan foydalanuvchilar: eʼloningiz (rasmlar, tavsif, joy, sana), ismingiz, avataringiz va qaytargan buyumlaringiz soni.',
      '• Telefon raqamingiz hech kimga koʻrsatilmaydi va eʼlonlarda saqlanmaydi. Aloqa faqat ilova ichidagi chat orqali boʻladi.',
      '• Yashirin belgini faqat siz koʻrasiz.',
      '• Soʻrovingizni (javob va dalil rasmi) faqat eʼlon muallifi koʻradi.',
      '• Chat xabarlarini faqat chat ishtirokchilari koʻradi.',
    ]),
    LegalSection('5. Maʼlumotlar qayerda saqlanadi', [
      'Topildi Google Firebase xizmatlaridan foydalanadi: hisobga kirish, maʼlumotlar bazasi, fayl ombori, server dasturlari va '
          'bildirishnomalar. Maʼlumotlar Google serverlarida, jumladan Oʻzbekistondan tashqarida saqlanishi mumkin.',
      'Kirish uchun Telegram boti ishlatiladi. Telegram oʻz maxfiylik siyosatiga ega.',
    ]),
    LegalSection('6. Saqlash muddati', [
      '• Hisob va profil — hisobni oʻchirguningizcha.',
      '• Eʼlonlar — oʻzingiz oʻchirguningizcha yoki hisob oʻchirilguncha. “Qaytarildi” eʼlonlar tarix sifatida qoladi.',
      '• 3 kun ichida javob berilmagan soʻrov bekor qilinadi va oʻchiriladi.',
      '• Chat xabarlari — hisob oʻchirilguncha.',
    ]),
    LegalSection('7. Huquqlaringiz', [
      '• Profilingiz va eʼlonlaringizni koʻrish va tahrirlash.',
      '• Eʼlon va soʻrovlaringizni oʻchirish.',
      '• Qurilma ruxsatlarini bekor qilish.',
      '• Siz haqingizdagi maʼlumotlar nusxasini olish yoki hisobingizni barcha maʼlumotlari bilan oʻchirishni soʻrash — '
          '{contact} ga yozing. Soʻrovni 30 kun ichida bajaramiz.',
    ]),
    LegalSection('8. Xavfsizlik', [
      'Ilova va serverlar oʻrtasidagi ulanish shifrlangan. Maʼlumotlarga kirish xavfsizlik qoidalari bilan cheklangan: '
          'har bir foydalanuvchi faqat oʻziga ruxsat etilgan maʼlumotni koʻradi. Shunga qaramay, hech bir tizim toʻliq himoyani kafolatlay olmaydi.',
    ]),
    LegalSection('9. Bolalar', [
      'Ilova 16 yoshga toʻlmaganlar uchun moʻljallanmagan. Agar bola maʼlumotlarini bizga yuborganini bilsangiz, '
          '{contact} ga yozing — ularni oʻchiramiz.',
    ]),
    LegalSection('10. Siyosatning oʻzgarishi', [
      'Siyosatni yangilashimiz mumkin. Muhim oʻzgarishlar haqida ilovada xabar beramiz; oxirgi yangilanish sanasi yuqorida koʻrsatilgan.',
    ]),
    LegalSection('11. Aloqa', ['Maʼlumotlaringiz boʻyicha savollar uchun: {contact}']),
  ],
);

const _privacyRu = LegalDocument(
  title: 'Политика конфиденциальности',
  updated: 'Последнее обновление: 30 октября 2026',
  intro:
      'Эта политика объясняет, какие данные собирает Topildi, зачем они используются и как защищаются. '
      'Персональные данные обрабатываются в соответствии с Законом Республики Узбекистан «О персональных данных».',
  sections: [
    LegalSection('1. Какие данные мы собираем', [
      '• Данные для входа: номер телефона, которым вы поделились при входе через Telegram.',
      '• Профиль: имя и аватар, которые вы указали.',
      '• Объявления: тип вещи, заголовок, описание, фото, место (точка на карте, город, район) и дата.',
      '• Тайный признак: примета вещи, которую знает только владелец.',
      '• Запросы: ваш ответ в запросе «Это моё» или «Я нашёл» и необязательное фото-доказательство.',
      '• Сообщения чата: сообщения в чате, который открывается после принятия запроса.',
      '• Устройство: токен устройства для уведомлений. Язык и тема хранятся только на вашем устройстве.',
    ]),
    LegalSection('2. Разрешения устройства', [
      '• Геолокация — только с вашего разрешения, чтобы выбрать место объявления и показать объявления рядом. В фоне не отслеживается.',
      '• Камера и галерея — загружаются только выбранные вами фото. Перед загрузкой фото сжимается, а метаданные '
          '(место съёмки, модель устройства) удаляются.',
      '• Уведомления — чтобы сообщать о новых запросах, сообщениях и напоминаниях.',
      'Эти разрешения можно отозвать в любой момент в настройках устройства.',
    ]),
    LegalSection('3. Как мы используем данные', [
      '• Вход в аккаунт и его защита.',
      '• Показ, поиск и фильтрация объявлений.',
      '• Связь владельца вещи и нашедшего, работа запросов и чатов.',
      '• Отправка уведомлений.',
      '• Предотвращение мошенничества и нарушений.',
      '• Исправление ошибок и улучшение приложения.',
      'Мы не продаём ваши данные и не передаём их третьим лицам в рекламных целях.',
    ]),
    LegalSection('4. Что видят другие', [
      '• Пользователи приложения: ваше объявление (фото, описание, место, дата), имя, аватар и число возвращённых вами вещей.',
      '• Ваш номер телефона никому не показывается и не хранится в объявлениях. Общение — только через чат в приложении.',
      '• Тайный признак видите только вы.',
      '• Ваш запрос (ответ и фото-доказательство) видит только автор объявления.',
      '• Сообщения чата видят только его участники.',
    ]),
    LegalSection('5. Где хранятся данные', [
      'Topildi использует сервисы Google Firebase: аутентификацию, базу данных, файловое хранилище, серверные функции и '
          'уведомления. Данные могут храниться на серверах Google, в том числе за пределами Узбекистана.',
      'Для входа используется бот Telegram. У Telegram своя политика конфиденциальности.',
    ]),
    LegalSection('6. Сроки хранения', [
      '• Аккаунт и профиль — пока вы не удалите аккаунт.',
      '• Объявления — пока вы их не удалите или пока не удалён аккаунт. Объявления «Возвращено» остаются в истории.',
      '• Запрос без ответа в течение 3 дней отменяется и удаляется.',
      '• Сообщения чата — пока не удалён аккаунт.',
    ]),
    LegalSection('7. Ваши права', [
      '• Просматривать и изменять профиль и объявления.',
      '• Удалять свои объявления и запросы.',
      '• Отзывать разрешения устройства.',
      '• Запросить копию данных о себе или удаление аккаунта со всеми данными — напишите: {contact}. '
          'Мы выполним запрос в течение 30 дней.',
    ]),
    LegalSection('8. Безопасность', [
      'Соединение между приложением и серверами зашифровано. Доступ к данным ограничен правилами безопасности: '
          'каждый пользователь видит только то, что ему разрешено. Тем не менее ни одна система не гарантирует полной защиты.',
    ]),
    LegalSection('9. Дети', [
      'Приложение не предназначено для лиц младше 16 лет. Если вы знаете, что ребёнок передал нам свои данные, '
          'напишите: {contact} — мы их удалим.',
    ]),
    LegalSection('10. Изменение политики', [
      'Мы можем обновлять политику. О важных изменениях сообщим в приложении; дата последнего обновления указана выше.',
    ]),
    LegalSection('11. Контакты', ['Вопросы о ваших данных: {contact}']),
  ],
);
