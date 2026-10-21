/// Uzbek Latin → Uzbek Cyrillic (official 1995 correspondence), for UI
/// strings. `{placeholders}` and a few brand words are left as they are.
String toUzbekCyrillic(String latin) {
  final out = StringBuffer();
  final s = latin;
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    // Placeholders stay untouched.
    if (c == '{') {
      final end = s.indexOf('}', i);
      if (end > i) {
        out.write(s.substring(i, end + 1));
        i = end + 1;
        continue;
      }
    }
    // Brand / foreign words kept in Latin.
    final keep = _keepAt(s, i);
    if (keep != null) {
      out.write(keep);
      i += keep.length;
      continue;
    }
    if (!_isLatin(c) && c != 'ʼ') {
      out.write(c);
      i++;
      continue;
    }
    final next = i + 1 < s.length ? s[i + 1] : '';
    final next2 = i + 2 < s.length ? s[i + 2] : '';
    final lower = c.toLowerCase();
    final upper = c != lower;
    // Whole word in capitals (e.g. "SMS") stays in capitals.
    final allCaps = upper && next.isNotEmpty && next != next.toLowerCase();
    String emit(String cyr, int consumed) {
      i += consumed;
      return upper ? (allCaps ? cyr.toUpperCase() : _cap(cyr)) : cyr;
    }

    final n = next.toLowerCase();
    String r;
    if (lower == 'o' && next == 'ʻ') {
      r = emit('ў', 2);
    } else if (lower == 'g' && next == 'ʻ') {
      r = emit('ғ', 2);
    } else if (lower == 's' && n == 'h') {
      r = emit('ш', 2);
    } else if (lower == 'c' && n == 'h') {
      r = emit('ч', 2);
    } else if (lower == 'y' && n == 'o' && next2 != 'ʻ') {
      r = emit('ё', 2);
    } else if (lower == 'y' && n == 'u') {
      r = emit('ю', 2);
    } else if (lower == 'y' && n == 'a') {
      r = emit('я', 2);
    } else if (lower == 'y' && n == 'e') {
      r = emit('е', 2);
    } else if (lower == 'e') {
      // э at the start of a word or after a vowel, е elsewhere.
      final prev = i > 0 ? s[i - 1].toLowerCase() : '';
      final startOfWord = prev.isEmpty || !_isLatin(prev) && prev != 'ʻ' && prev != 'ʼ';
      r = emit(startOfWord || 'aeiou'.contains(prev) ? 'э' : 'е', 1);
    } else if (c == 'ʼ') {
      r = 'ъ';
      i++;
    } else {
      r = emit(_single[lower] ?? lower, 1);
    }
    out.write(r);
  }
  return out.toString();
}

const _single = {
  'a': 'а', 'b': 'б', 'c': 'с', 'd': 'д', 'f': 'ф', 'g': 'г', 'h': 'ҳ', 'i': 'и', 'j': 'ж', //
  'k': 'к', 'l': 'л', 'm': 'м', 'n': 'н', 'o': 'о', 'p': 'п', 'q': 'қ', 'r': 'р', 's': 'с', //
  't': 'т', 'u': 'у', 'v': 'в', 'w': 'в', 'x': 'х', 'y': 'й', 'z': 'з',
};

const _keep = ['Google', 'OpenStreetMap'];

String? _keepAt(String s, int i) {
  for (final k in _keep) {
    if (s.startsWith(k, i)) return k;
  }
  return null;
}

bool _isLatin(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 65 && u <= 90) || (u >= 97 && u <= 122);
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
