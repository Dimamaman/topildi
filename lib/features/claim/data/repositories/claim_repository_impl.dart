import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/firebase_failure.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../listing/data/datasources/listing_remote_datasource.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/claim.dart';
import '../../domain/repositories/claim_repository.dart';
import '../datasources/claim_remote_datasource.dart';

@LazySingleton(as: ClaimRepository)
class ClaimRepositoryImpl implements ClaimRepository {
  const ClaimRepositoryImpl(this._claims, this._listings, this._network, this._session);

  final ClaimRemoteDataSource _claims;
  final ListingRemoteDataSource _listings;
  final NetworkInfo _network;
  final Session _session;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      return right(await run());
    } catch (e) {
      return left(failureOf(e));
    }
  }

  Future<ListingModel> _listing(String id) async => await _listings.fetchById(id) ?? (throw const NotFoundFailure());

  Future<Claim> _claim(String id) async => await _claims.byId(id) ?? (throw const NotFoundFailure());

  @override
  FutureEither<ClaimTarget> getTarget(String listingId) => _guard(() async {
        final model = await _listing(listingId);
        final mine = await _claims.byClaimant(_session.userId, listingId);
        return ClaimTarget(
          listing: model.toEntity(),
          attemptsLeft: ClaimTarget.maxAttempts - mine.length,
          hasPending: mine.any((c) => c.status == ClaimStatus.pending),
        );
      });

  @override
  FutureEither<Claim> submit(SubmitClaimParams params) => _guard(() async {
        final model = await _listing(params.listingId);
        if (model.author.id == _session.userId) throw const ForbiddenFailure();
        final mine = await _claims.byClaimant(_session.userId, params.listingId);
        if (mine.length >= ClaimTarget.maxAttempts) throw ValidationFailure(tr('Urinishlar tugadi'));
        return _claims.add(
          listing: model,
          claimant: PublicUser(id: _session.userId, displayName: _session.displayName),
          params: params,
        );
      });

  @override
  FutureEither<ClaimReview> getReview(String listingId) => _guard(() async {
        final model = await _listing(listingId);
        // The hidden detail leaves the data layer only for the author.
        if (model.author.id != _session.userId) throw const ForbiddenFailure();
        return ClaimReview(
          listing: model.toEntity(),
          hiddenDetail: model.hiddenDetail,
          claims: await _claims.forListing(listingId),
        );
      });

  @override
  FutureEither<String> accept(String claimId) => _guard(() async {
        final claim = await _claim(claimId);
        final model = await _listing(claim.listingId);
        if (model.author.id != _session.userId) throw const ForbiddenFailure();
        return _claims.accept(claim, model);
      });

  @override
  FutureEither<Claim> reject(String claimId) => _guard(() async {
        final claim = await _claim(claimId);
        final model = await _listing(claim.listingId);
        if (model.author.id != _session.userId) throw const ForbiddenFailure();
        return _claims.reject(claimId);
      });
}
