import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/core/location/geo_point.dart';
import 'package:topildi/core/media/app_dirs.dart';
import 'package:topildi/core/session/session.dart';
import 'package:topildi/core/storage/stores.dart';
import 'package:topildi/core/theme/theme_cubit.dart';

void main() {
  group('GeoPoint.approximate', () {
    test('never publishes the exact point but stays within the ~300 m cell', () {
      const exact = GeoPoint(41.28317, 69.20461);
      final cell = exact.approximate();
      expect(cell, isNot(exact));
      // Max distance to a 300 m cell centre is half the diagonal (~212 m).
      expect(exact.distanceTo(cell), lessThan(215));
    });

    test('nearby points in the same cell map to the same centre', () {
      final a = const GeoPoint(41.28301, 69.20401).approximate();
      final b = const GeoPoint(41.28305, 69.20405).approximate();
      expect(a, b);
      expect(a.approximate(), a);
    });

    test('formatDistance', () {
      expect(formatDistance(330), '350 m');
      expect(formatDistance(1240), '1,2 km');
    });
  });

  group('Session persistence', () {
    late MemoryKeyValueStore kv;
    late MemorySecureStore secure;
    Session make() => Session(kv, secure, const AppDirs('/docs/photos'));

    setUp(() {
      kv = MemoryKeyValueStore();
      secure = MemorySecureStore();
    });

    test('state survives a new Session (app restart)', () async {
      await make().markOnboardingSeen();
      await make().signIn(phone: '901234567');
      await make().setName('Malika', 'Karimova');

      final restarted = make();
      expect(restarted.onboardingSeen, isTrue);
      expect(restarted.signedIn, isTrue);
      expect(restarted.displayName, 'Malika K.');
    });

    test('phone number is kept only in secure storage', () async {
      await make().signIn(phone: '901234567');
      expect(await secure.read(StoreKeys.phone), '901234567');
      expect(kv.getString(StoreKeys.phone), isNull);
    });

    test('sign out clears phone and token', () async {
      final s = make();
      await s.signIn(phone: '901234567');
      await s.signOut();
      expect(s.signedIn, isFalse);
      expect(await secure.read(StoreKeys.phone), isNull);
      expect(await secure.read(StoreKeys.authToken), isNull);
    });

    test('avatar is stored by file name and resolved against the photos dir', () async {
      final s = make();
      await s.setAvatar('/docs/photos/123.jpg');
      expect(kv.getString(StoreKeys.avatarPath), '123.jpg');
      expect(s.avatarPath, '/docs/photos/123.jpg');
    });
  });

  test('ThemeCubit restores the saved mode', () {
    final kv = MemoryKeyValueStore();
    ThemeCubit(kv).set(ThemeMode.dark);
    expect(ThemeCubit(kv).state, ThemeMode.dark);
  });
}
