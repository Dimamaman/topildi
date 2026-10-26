import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:topildi/core/network/network_info.dart';
import 'package:topildi/core/push/push_service.dart';
import 'package:topildi/core/session/session.dart';
import 'package:topildi/core/storage/stores.dart';
import 'package:topildi/features/claim/data/datasources/claim_remote_datasource.dart';
import 'package:topildi/features/listing/data/datasources/listing_remote_datasource.dart';
import 'package:topildi/features/profile/data/repositories/profile_repository_impl.dart';

class _Push extends Mock implements PushService {}

class _Session extends Mock implements Session {}

class _Listings extends Mock implements ListingRemoteDataSource {}

class _Claims extends Mock implements ClaimRemoteDataSource {}

class _Network extends Mock implements NetworkInfo {}

void main() {
  late _Push push;
  late _Session session;
  late MemoryKeyValueStore kv;
  late ProfileRepositoryImpl repo;

  setUp(() {
    push = _Push();
    session = _Session();
    kv = MemoryKeyValueStore();
    when(push.start).thenAnswer((_) async {});
    when(push.stop).thenAnswer((_) async {});
    when(session.signOut).thenAnswer((_) async {});
    repo = ProfileRepositoryImpl(_Listings(), _Claims(), session, _Network(), kv, push);
  });

  test('the Bildirishnomalar switch registers and unregisters the device', () async {
    await repo.setNotifications(false);
    verify(push.stop).called(1);
    expect(kv.getBool(StoreKeys.notificationsOn), isFalse);

    await repo.setNotifications(true);
    verify(push.start).called(1);
  });

  test('sign-out removes the device first, while the rules still allow it', () async {
    await repo.signOut();
    verifyInOrder([push.stop, session.signOut]);
  });
}
