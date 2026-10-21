import '../l10n/app_language.dart';
import '../l10n/tr.dart';

/// Relative date labels used across listings and chats, in the current
/// [AppLanguage]: "21-oktabr" / "21-октябр" / "21 октября".
abstract final class TDate {
  static const _months = [
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ];

  /// Russian genitive ("21 октября", "с сентября").
  static const _ruMonthsGen = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static const _monthsNominative = [
    'Yanvar',
    'Fevral',
    'Mart',
    'Aprel',
    'May',
    'Iyun',
    'Iyul',
    'Avgust',
    'Sentyabr',
    'Oktyabr',
    'Noyabr',
    'Dekabr',
  ];

  /// Uzbek Cyrillic spellings (not derivable letter by letter: "oktabr" → "октябр").
  static const _cyrlMonths = [
    'январ',
    'феврал',
    'март',
    'апрел',
    'май',
    'июн',
    'июл',
    'август',
    'сентябр',
    'октябр',
    'ноябр',
    'декабр',
  ];

  static const _weekdays = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];

  static bool get _ru => AppLanguage.current == AppLanguage.ru;
  static bool get _cyrl => AppLanguage.current == AppLanguage.uzCyrl;

  static String _month(int m) => _cyrl ? _cyrlMonths[m - 1] : _months[m - 1];

  static String _monthTitle(int m) {
    final s = _cyrl ? _cyrlMonths[m - 1] : _monthsNominative[m - 1];
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static int _daysAgo(DateTime d, DateTime? now) {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  }

  /// "21-oktabr" · "21 октября".
  static String dayMonth(DateTime d) => _ru ? '${d.day} ${_ruMonthsGen[d.month - 1]}' : '${d.day}-${_month(d.month)}';

  /// "Bugun, 09:40" · "Kecha, 18:15" · "18-oktabr".
  static String relative(DateTime d, {DateTime? now, bool withTimeForOld = false}) {
    final diff = _daysAgo(d, now);
    if (diff == 0) return '${tr('Bugun')}, ${_hm(d)}';
    if (diff == 1) return '${tr('Kecha')}, ${_hm(d)}';
    return withTimeForOld ? '${dayMonth(d)}, ${_hm(d)}' : dayMonth(d);
  }

  /// "Bugun" · "Kecha" · "21-oktabr" (no time).
  static String day(DateTime d, {DateTime? now}) {
    final diff = _daysAgo(d, now);
    if (diff == 0) return tr('Bugun');
    if (diff == 1) return tr('Kecha');
    return dayMonth(d);
  }

  /// Chat list time: "14:20" today · "Kecha" · weekday within the week · "19-oktabr".
  static String chat(DateTime d, {DateTime? now}) {
    final diff = _daysAgo(d, now);
    if (diff == 0) return _hm(d);
    if (diff == 1) return tr('Kecha');
    if (diff < 7) return tr(_weekdays[d.weekday - 1]);
    return dayMonth(d);
  }

  /// "Sentyabr 2026 dan beri aʼzo" · "С нами с сентября 2026".
  static String memberSince(DateTime d) => _ru
      ? 'С нами с ${_ruMonthsGen[d.month - 1]} ${d.year}'
      : tr('{month} {year} dan beri aʼzo', {'month': _monthTitle(d.month), 'year': d.year});

  /// "20-oktabr, 09:40".
  static String full(DateTime d) => '${dayMonth(d)}, ${_hm(d)}';

  static String time(DateTime d) => _hm(d);
}
