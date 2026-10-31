import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/core/storage/stores.dart';
import 'package:topildi/features/listing/presentation/seen_returned.dart';

/// Which stories have been watched: on the device, nowhere else.
void main() {
  late MemoryKeyValueStore kv;

  setUp(() => kv = MemoryKeyValueStore());

  test('nothing is watched until a story comes up', () {
    expect(SeenReturned(kv).seen.value, isEmpty);
  });

  test('a watched id is remembered and the strip is told at once', () async {
    final store = SeenReturned(kv);
    var notified = 0;
    store.seen.addListener(() => notified++);

    await store.mark('l1');
    expect(store.contains('l1'), isTrue);
    expect(notified, 1);

    // The same story again changes nothing, so the strip does not rebuild.
    await store.mark('l1');
    expect(notified, 1);
  });

  test('it survives the next start', () async {
    await SeenReturned(kv).mark('l1');
    expect(SeenReturned(kv).contains('l1'), isTrue);
  });

  test('the key cannot grow forever: the oldest ids drop out', () async {
    final store = SeenReturned(kv);
    for (var i = 0; i < SeenReturned.capacity + 5; i++) {
      await store.mark('l$i');
    }
    expect(store.seen.value, hasLength(SeenReturned.capacity));
    expect(store.contains('l0'), isFalse);
    expect(store.contains('l${SeenReturned.capacity + 4}'), isTrue);
  });
}
