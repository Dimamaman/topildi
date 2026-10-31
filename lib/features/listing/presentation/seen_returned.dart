import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/storage/stores.dart';

/// Which returned items this person has already watched, so the feed's strip
/// can let its ring go quiet — as stories do everywhere.
///
/// Kept on the device only: what someone watched is nobody else's business,
/// and nothing here is worth a Firestore write. Only the ids still worth
/// knowing about are kept ([capacity]), so the key cannot grow forever.
@lazySingleton
class SeenReturned {
  SeenReturned(this._kv) : seen = ValueNotifier(_read(_kv));

  final KeyValueStore _kv;

  /// The strip listens: a story watched just now greys its ring at once.
  final ValueNotifier<Set<String>> seen;

  /// Comfortably more than the ten the strip can show, so going back a screen
  /// never forgets what was watched a minute ago.
  static const capacity = 40;

  static const _separator = ',';

  bool contains(String id) => seen.value.contains(id);

  Future<void> mark(String id) async {
    if (id.isEmpty || seen.value.contains(id)) return;
    // Newest last, so the oldest ids are the ones dropped.
    final next = [...seen.value.where((e) => e != id), id];
    final kept = next.length <= capacity ? next : next.sublist(next.length - capacity);
    seen.value = kept.toSet();
    await _kv.setString(StoreKeys.seenReturned, kept.join(_separator));
  }

  static Set<String> _read(KeyValueStore kv) {
    final raw = kv.getString(StoreKeys.seenReturned) ?? '';
    return raw.isEmpty ? <String>{} : raw.split(_separator).where((e) => e.isNotEmpty).toSet();
  }
}
