import '../../../../core/usecase/usecase.dart';
import '../entities/claim.dart';

abstract interface class ClaimRepository {
  FutureEither<ClaimTarget> getTarget(String listingId);

  FutureEither<Claim> submit(SubmitClaimParams params);

  /// Fails with ForbiddenFailure unless the signed-in user wrote the listing.
  FutureEither<ClaimReview> getReview(String listingId);

  /// Accepts a claim and returns the id of the chat it opens.
  FutureEither<String> accept(String claimId);

  FutureEither<Claim> reject(String claimId);
}
