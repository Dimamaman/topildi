import '../../../../core/usecase/usecase.dart';
import '../entities/claim.dart';

abstract interface class ClaimRepository {
  FutureEither<ClaimTarget> getTarget(String listingId);

  FutureEither<Claim> submit(SubmitClaimParams params);

  /// Fails with ForbiddenFailure unless the signed-in user wrote the listing.
  FutureEither<ClaimReview> getReview(String listingId);

  /// Takes back the signed-in user's waiting claim on the listing once it
  /// has gone unanswered for [ClaimTarget.cancelAfter]; the attempt is returned.
  FutureEither<void> cancel(String listingId);

  /// Accepts a claim and returns the id of the chat it opens.
  FutureEither<String> accept(String claimId);

  FutureEither<Claim> reject(String claimId);

  /// Pending claims per listing of the signed-in user, live.
  StreamEither<Map<String, int>> watchPendingCounts();
}
