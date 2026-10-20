import '../../../../core/usecase/usecase.dart';
import '../entities/listing.dart';

abstract interface class ListingRepository {
  FutureEither<ListingPage> getListings(ListingQuery query);

  FutureEither<Listing> getListing(String id);

  /// Emits when listings were added or changed.
  Stream<void> get changes;
}
