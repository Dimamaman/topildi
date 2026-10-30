import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/firebase_failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/session/session.dart';
import '../../../../core/storage/stores.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../claim/data/datasources/claim_remote_datasource.dart';
import '../../../listing/data/datasources/listing_remote_datasource.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/profile_summary.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/account_remote_datasource.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._listings, this._claims, this._session, this._network, this._kv, this._push, this._account);

  final ListingRemoteDataSource _listings;
  final ClaimRemoteDataSource _claims;
  final Session _session;
  final NetworkInfo _network;
  final KeyValueStore _kv;
  final PushService _push;
  final AccountRemoteDataSource _account;

  bool get _notificationsOn => _kv.getBool(StoreKeys.notificationsOn) ?? true;

  @override
  FutureEither<ProfileSummary> getMine() async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final mine = await _listings.fetchByAuthor(_session.userId);
      final pending = await _claims.pendingCountsForAuthor(_session.userId);
      final active = <MyListing>[];
      final returned = <MyListing>[];
      for (final m in mine) {
        if (m.status == ListingStatus.returned) {
          returned.add(MyListing(listing: m.toEntity()));
        } else {
          active.add(MyListing(listing: m.toEntity(), pendingClaims: pending[m.id] ?? 0));
        }
      }
      return right(ProfileSummary(
        displayName: _session.displayName,
        memberSince: _session.memberSince,
        active: active,
        returned: returned.where((m) => m.listing.isFound).toList(),
        gotBack: returned.where((m) => !m.listing.isFound).length,
        notificationsOn: _notificationsOn,
        avatarPath: _session.avatarPath,
        avatarTone: _session.avatarTone,
        avatarEmoji: _session.avatarEmoji,
      ));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<void> setNotifications(bool on) async {
    await _kv.setBool(StoreKeys.notificationsOn, on);
    on ? await _push.start() : await _push.stop();
    return right(null);
  }

  @override
  FutureEither<void> signOut() async {
    // While still signed in: the rules let only the owner delete the token.
    await _push.stop();
    await _session.signOut();
    return right(null);
  }

  @override
  FutureEither<void> deleteAccount() async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    // The device token goes first, while the rules still let the owner delete it.
    await _push.stop();
    try {
      await _account.delete();
    } catch (e) {
      if (_notificationsOn) await _push.start();
      return left(failureOf(e));
    }
    await _session.signOut();
    return right(null);
  }
}
