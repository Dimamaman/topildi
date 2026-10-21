/// Uzbek relative date labels used across listings and chats.
abstract final class TDate {
  static const _months = [
    'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun',
    'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr',
  ];

  static String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String dayMonth(DateTime d) => '${d.day}-${_months[d.month - 1]}';

  /// "Bugun, 09:40" · "Kecha, 18:15" · "18-oktabr".
  static String relative(DateTime d, {DateTime? now, bool withTimeForOld = false}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Bugun, ${_hm(d)}';
    if (diff == 1) return 'Kecha, ${_hm(d)}';
    return withTimeForOld ? '${dayMonth(d)}, ${_hm(d)}' : dayMonth(d);
  }

  /// "Bugun" · "Kecha" · "21-oktabr" (no time).
  static String day(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Bugun';
    if (diff == 1) return 'Kecha';
    return dayMonth(d);
  }

  static const _weekdays = ['Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba', 'Yakshanba'];

  /// Chat list time: "14:20" today · "Kecha" · weekday within the week · "19-oktabr".
  static String chat(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return _hm(d);
    if (diff == 1) return 'Kecha';
    if (diff < 7) return _weekdays[d.weekday - 1];
    return dayMonth(d);
  }

  /// "20-oktabr, 09:40".
  static String full(DateTime d) => '${dayMonth(d)}, ${_hm(d)}';

  static String time(DateTime d) => _hm(d);
}
