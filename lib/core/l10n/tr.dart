import 'app_language.dart';
import 'cyrillic.dart';
import 'ru.dart';

/// Translates an interface string written in Uzbek (Latin) into the
/// current [AppLanguage]. `{name}` placeholders are filled from [args]
/// after translation, so names and numbers are never transliterated.
///
///     tr('Chatlar')
///     tr('{n} ta natijani koʻrsatish', {'n': count})
String tr(String uz, [Map<String, Object?> args = const {}]) {
  var s = switch (AppLanguage.current) {
    AppLanguage.uzLatn => uz,
    AppLanguage.uzCyrl => _cyrl[uz] ??= toUzbekCyrillic(uz),
    AppLanguage.ru => ruStrings[uz] ?? uz,
  };
  args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

final _cyrl = <String, String>{};
