import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../chat/data/datasources/chat_mock_datasource.dart';
import '../../../listing/data/datasources/listing_mock_datasource.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/claim.dart';
import '../../domain/repositories/claim_repository.dart';
import '../datasources/claim_mock_datasource.dart';

@LazySingleton(as: ClaimRepository)
class ClaimRepositoryImpl implements ClaimRepository {
  const ClaimRepositoryImpl(this._claims, this._listings, this._chats, this._network, this._session);

  final ClaimMockDataSource _claims;
  final ListingMockDataSource _listings;
  final ChatMockDataSource _chats;
  final NetworkInfo _network;
  final Session _session;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      return right(await run());
    } on Failure catch (f) {
      return left(f);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  Future<ListingModel> _listing(String id) async => await _listings.fetchById(id) ?? (throw const NotFoundFailure());

  int _attemptsLeft(String listingId) =>
      ClaimTarget.maxAttempts - _claims.attemptsBy(_session.userId, listingId);

  @override
  FutureEither<ClaimTarget> getTarget(String listingId) => _guard(() async {
        final model = await _listing(listingId);
        return ClaimTarget(listing: model.toEntity(), attemptsLeft: _attemptsLeft(listingId));
      });

  @override
  FutureEither<Claim> submit(SubmitClaimParams params) => _guard(() async {
        final model = await _listing(params.listingId);
        if (model.author.id == _session.userId) throw const ForbiddenFailure();
        if (_attemptsLeft(params.listingId) <= 0) throw const ValidationFailure('Urinishlar tugadi');
        return _claims.add(Claim(
          id: 'cl${DateTime.now().microsecondsSinceEpoch}',
          listingId: params.listingId,
          claimant: PublicUser(id: _session.userId, displayName: _session.displayName),
          answer: params.answer.trim(),
          hasProofPhoto: params.hasProofPhoto,
          proofPath: params.proofPath,
          createdAt: DateTime.now(),
        ));
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
        final claim = _claims.byId(claimId) ?? (throw const NotFoundFailure());
        final model = await _listing(claim.listingId);
        if (model.author.id != _session.userId) throw const ForbiddenFailure();
        await _claims.setStatus(claimId, ClaimStatus.accepted);
        return _chats.openChat(
          listingId: model.id,
          listingTitle: model.title,
          category: model.category,
          tint: model.tint,
          claimant: claim.claimant,
        );
      });

  @override
  FutureEither<Claim> reject(String claimId) => _guard(() async {
        final claim = _claims.byId(claimId) ?? (throw const NotFoundFailure());
        final model = await _listing(claim.listingId);
        if (model.author.id != _session.userId) throw const ForbiddenFailure();
        return _claims.setStatus(claimId, ClaimStatus.rejected);
      });
}
