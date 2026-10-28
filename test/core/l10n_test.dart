import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/core/l10n/app_language.dart';
import 'package:topildi/core/l10n/cyrillic.dart';
import 'package:topildi/core/l10n/ru.dart';
import 'package:topildi/core/l10n/tr.dart';
import 'package:topildi/core/utils/date_format.dart';
import 'package:topildi/features/listing/domain/entities/regions.dart';

/// Strings passed to tr() through a variable (constant lists) rather than
/// as a literal, so the source scan below cannot see them.
const _indirect = [
  'Chatlar', 'Bildirishnomalar', 'Mening eʼlonlarim', 'Ichidagi narsalar', 'Rang yoki naqsh', 'Yozuv, stiker', //
  'Tirnalgan joy', 'rasm va tur', 'maʼlumotlar', 'joy va sana', 'Bir', 'Ikki', 'Uch', 'Toʻrt', 'Besh', 'Olti', //
  'Yetti', 'Sakkiz', 'Toʻqqiz', 'Oʻn', 'Barcha tumanlar', 'Bugun', '7 kun', '30 kun', 'Tanlash', 'Tizim', //
  'Yorugʻ', 'Qorongʻi', 'Yashirin belgi', 'Buni faqat siz koʻrasiz', 'Toshkent', 'Samarqand', 'Buxoro', //
  'Andijon', 'Namangan', 'Fargʻona', 'Toshkent viloyati', 'Jizzax', 'Navoiy', 'Qashqadaryo', 'Qoraqalpogʻiston', //
  'Sirdaryo', 'Surxondaryo', 'Xorazm', 'Bektemir', 'Chilonzor', 'Mirobod', 'Mirzo Ulugʻbek', //
  'Olmazor', 'Sergeli', 'Shayxontohur', 'Uchtepa', 'Yakkasaroy', 'Yangihayot', 'Yashnobod', 'Yunusobod', //
  'Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba',
];

void main() {
  tearDown(() => AppLanguage.current = AppLanguage.uzLatn);

  test('every tr() string in lib/ has a Russian translation', () {
    final keys = <String>{
      ..._indirect,
      ...Regions.cities,
      for (final c in Regions.cities) ...Regions.districtsOf(c),
    };
    final literal = RegExp(r"\btr\(\s*'((?:[^'\\]|\\.)*)'");
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.contains('core/l10n/')) continue;
      for (final m in literal.allMatches(f.readAsStringSync())) {
        keys.add(m.group(1)!.replaceAll(r'\n', '\n'));
      }
    }
    final missing = keys.where((k) => !ruStrings.containsKey(k)).toList();
    expect(missing, isEmpty, reason: 'Add to lib/core/l10n/ru.dart');
  });

  test('Uzbek Latin → Cyrillic', () {
    expect(toUzbekCyrillic('Yoʻqolgan'), 'Йўқолган');
    expect(toUzbekCyrillic('Eʼlon berish'), 'Эълон бериш');
    expect(toUzbekCyrillic('Toshkent'), 'Тошкент');
    expect(toUzbekCyrillic('Fargʻona'), 'Фарғона');
    expect(toUzbekCyrillic('Chatlar'), 'Чатлар');
    expect(toUzbekCyrillic('Yetti'), 'Етти');
    expect(toUzbekCyrillic('Hammasi oʻqildi'), 'Ҳаммаси ўқилди');
    expect(toUzbekCyrillic('maʼlumotlar'), 'маълумотлар');
    expect(toUzbekCyrillic('SMS kod'), 'СМС код');
    expect(toUzbekCyrillic('Google orqali davom etish'), 'Google орқали давом этиш');
    expect(toUzbekCyrillic('{n} ta natijani koʻrsatish'), '{n} та натижани кўрсатиш');
  });

  test('tr fills placeholders after translating', () {
    AppLanguage.current = AppLanguage.ru;
    expect(tr('{n} ta natijani koʻrsatish', {'n': 18}), 'Показать результаты: 18');
    AppLanguage.current = AppLanguage.uzCyrl;
    expect(tr('Boshqalar faqat bosh harfni koʻradi: {publicName}', {'publicName': 'Dilshod A.'}),
        'Бошқалар фақат бош ҳарфни кўради: Dilshod A.');
  });

  test('dates follow the language', () {
    final d = DateTime(2026, 10, 21);
    final now = DateTime(2026, 10, 25);
    expect(TDate.day(d, now: now), '21-oktabr');
    AppLanguage.current = AppLanguage.uzCyrl;
    expect(TDate.day(d, now: now), '21-октябр');
    AppLanguage.current = AppLanguage.ru;
    expect(TDate.day(d, now: now), '21 октября');
    expect(TDate.day(DateTime(2026, 10, 24), now: now), 'Вчера');
    expect(TDate.memberSince(DateTime(2026, 9)), 'С нами с сентября 2026');
  });
}
