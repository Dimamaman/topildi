import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:topildi/core/network/network_info.dart';
import 'package:topildi/core/push/push_service.dart';
import 'package:topildi/core/session/session.dart';
import 'package:topildi/core/storage/stores.dart';
import 'package:topildi/features/claim/data/datasources/claim_remote_datasource.dart';
import 'package:topildi/features/listing/data/datasources/listing_remote_datasource.dart';
import 'package:topildi/features/profile/data/datasources/account_remote_datasource.dart';
import 'package:topildi/features/profile/data/datasources/consent_remote_datasource.dart';
import 'package:topildi/features/profile/data/repositories/profile_repository_impl.dart';

class _Push extends Mock implements PushService {}

class _Session extends Mock implements Session {}

class _Listings extends Mock implements ListingRemoteDataSource {}

class _Claims extends Mock implements ClaimRemoteDataSource {}

class _Network extends Mock implements NetworkInfo {}

class _Account extends Mock implements AccountRemoteDataSource {}

void main() {
  late _Push push;
  late _Session session;
  late MemoryKeyValueStore kv;
  late ProfileRepositoryImpl repo;
  late _Network network;
  late _Account account;
  late MockConsentDataSource consent;

  setUp(() {
    push = _Push();
    session = _Session();
    kv = MemoryKeyValueStore();
    when(push.start).thenAnswer((_) async {});
    when(push.stop).thenAnswer((_) async {});
    when(session.signOut).thenAnswer((_) async {});
    network = _Network();
    account = _Account();
    when(() => network.isConnected).thenAnswer((_) async => true);
    consent = MockConsentDataSource();
    repo = ProfileRepositoryImpl(_Listings(), _Claims(), session, network, kv, push, account, consent);
  });

  test('the Bildirishnomalar switch registers and unregisters the device', () async {
    await repo.setNotifications(false);
    verify(push.stop).called(1);
    expect(kv.getBool(StoreKeys.notificationsOn), isFalse);

    await repo.setNotifications(true);
    verify(push.start).called(1);
  });

  group('“Qaytarganlarimda ismim koʻrinsin”', () {
    test('a name is never shown until the person turns it on', () async {
      expect((await repo.getShowNameOnReturns()).getOrElse((_) => true), isFalse);
    });

    test('the server hears first, then the device remembers', () async {
      await repo.setShowNameOnReturns(true);
      expect(consent.showNameOnReturns, isTrue);
      expect(kv.getBool(StoreKeys.showNameOnReturns), isTrue);
      expect((await repo.getShowNameOnReturns()).getOrElse((_) => false), isTrue);
    });

    test('offline it stays off: the switch must not promise what no listing carries', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      expect((await repo.setShowNameOnReturns(true)).isLeft(), isTrue);
      expect(kv.getBool(StoreKeys.showNameOnReturns), isNull);
    });
  });

  test('sign-out removes the device first, while the rules still allow it', () async {
    await repo.signOut();
    verifyInOrder([push.stop, session.signOut]);
  });

  test('deleting the account: device token, then the server, then sign-out', () async {
    when(account.delete).thenAnswer((_) async {});
    expect((await repo.deleteAccount()).isRight(), isTrue);
    verifyInOrder([push.stop, account.delete, session.signOut]);
  });

  test('a failed deletion keeps the user signed in and push back on', () async {
    when(account.delete).thenThrow(Exception('boom'));
    expect((await repo.deleteAccount()).isLeft(), isTrue);
    verify(push.start).called(1);
    verifyNever(session.signOut);
  });

  test('no deletion attempt offline', () async {
    when(() => network.isConnected).thenAnswer((_) async => false);
    expect((await repo.deleteAccount()).isLeft(), isTrue);
    verifyNever(account.delete);
    verifyNever(push.stop);
  });
}
