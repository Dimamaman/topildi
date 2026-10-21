import '../../../../core/usecase/usecase.dart';
import '../entities/listing.dart';

abstract interface class ListingRepository {
  FutureEither<ListingPage> getListings(ListingQuery query);

  FutureEither<Listing> getListing(String id);

  /// Author only; fails with ForbiddenFailure otherwise.
  FutureEither<void> delete(String id);

  /// Author only: closes the listing as returned to its owner.
  FutureEither<Listing> markReturned(String id);

  /// Emits when listings were added or changed.
  Stream<void> get changes;
}
