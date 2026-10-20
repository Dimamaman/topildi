import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../claim/data/datasources/claim_mock_datasource.dart';
import '../../../listing/data/datasources/listing_mock_datasource.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/profile_summary.dart';
import '../../domain/repositories/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._listings, this._claims, this._session, this._network);

  final ListingMockDataSource _listings;
  final ClaimMockDataSource _claims;
  final Session _session;
  final NetworkInfo _network;
  bool _notificationsOn = true;

  @override
  FutureEither<ProfileSummary> getMine() async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final mine = (await _listings.fetchAll()).where((m) => m.author.id == _session.userId).toList()
        ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
      final active = <MyListing>[];
      final returned = <MyListing>[];
      for (final m in mine) {
        if (m.status == ListingStatus.returned) {
          returned.add(MyListing(listing: m.toEntity()));
        } else {
          active.add(MyListing(listing: m.toEntity(), pendingClaims: _claims.pendingFor(m.id)));
        }
      }
      return right(ProfileSummary(
        displayName: _session.displayName,
        memberSince: DateTime(2026, 9),
        active: active,
        returned: returned.where((m) => m.listing.isFound).toList(),
        gotBack: returned.where((m) => !m.listing.isFound).length,
        notificationsOn: _notificationsOn,
      ));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<void> setNotifications(bool on) async {
    _notificationsOn = on;
    return right(null);
  }

  @override
  FutureEither<void> signOut() async {
    _session
      ..signedIn = false
      ..phone = null;
    return right(null);
  }
}
