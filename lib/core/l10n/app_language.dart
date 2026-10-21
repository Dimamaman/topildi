import 'package:flutter/widgets.dart';

/// Interface languages. Source strings are written in Uzbek (Latin);
/// Cyrillic is derived from them, Russian comes from [ruStrings].
enum AppLanguage {
  uzLatn('uz_Latn', 'Oʻzbekcha', Locale('uz')),
  uzCyrl('uz_Cyrl', 'Ўзбекча', Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl')),
  ru('ru', 'Русский', Locale('ru'));

  const AppLanguage(this.code, this.nativeName, this.locale);

  /// Stored value.
  final String code;

  /// Name shown in the language menu, always in that language.
  final String nativeName;

  final Locale locale;

  /// Locale handed to Flutter's Material/Cupertino localizations
  /// (they have Uzbek in one script only).
  Locale get materialLocale => this == ru ? const Locale('ru') : const Locale('uz');

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.uzLatn);

  /// Language every [tr] call uses. Set by `LanguageCubit`.
  static AppLanguage current = AppLanguage.uzLatn;
}
