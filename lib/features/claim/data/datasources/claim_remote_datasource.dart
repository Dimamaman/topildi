import '../../../listing/data/models/listing_model.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/claim.dart';

/// Where claims ("Bu meniki") live: Firestore in the app, an in-memory mock
/// in tests. Accepting a claim opens its chat in the same write.
abstract interface class ClaimRemoteDataSource {
  /// Every claim on the listing, newest first (author only).
  Future<List<Claim>> forListing(String listingId);

  /// Pending claims per listing across all of [authorId]'s listings.
  Future<Map<String, int>> pendingCountsForAuthor(String authorId);

  /// The same, live: emits again whenever a claim arrives or is answered.
  Stream<Map<String, int>> watchPendingCounts(String authorId);

  /// [claimantId]'s own claims on the listing (attempts, pending state).
  Future<List<Claim>> byClaimant(String claimantId, String listingId);

  Future<Claim?> byId(String id);

  /// One claim, live (read by its claimant or the listing's author); null
  /// once it no longer exists (taken back).
  Stream<Claim?> watch(String id);

  /// Stores a new pending claim as the [claimant]'s next attempt; a local
  /// proof photo is uploaded first.
  Future<Claim> add({required ListingModel listing, required PublicUser claimant, required SubmitClaimParams params});

  Future<Claim> reject(String id);

  /// Deletes the claimant's own waiting claim and its proof photo.
  Future<void> remove(Claim claim);

  /// Marks the claimant's own waiting claim cancelled (the attempt stays used).
  Future<void> cancel(Claim claim);

  /// Marks the claim accepted and opens the chat between the listing's
  /// author and the claimant; returns the chat id.
  Future<String> accept(Claim claim, ListingModel listing);
}
