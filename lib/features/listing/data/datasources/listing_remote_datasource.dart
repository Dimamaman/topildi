import '../../domain/entities/listing.dart';
import '../models/listing_model.dart';

/// Where listings live: Firestore in the app, an in-memory mock in tests.
/// Repositories (listing, create, profile, claim, chat) depend on this,
/// never on a concrete source.
abstract interface class ListingRemoteDataSource {
  /// Fires after any listing is added, updated or removed.
  Stream<void> get changes;

  /// Active listings of [query]'s type matching its filter (city, district,
  /// period, categories), newest first. Free-text search is applied by the
  /// repository.
  Future<List<ListingModel>> fetch(ListingQuery query);

  /// Every listing written by [authorId] (any status), newest first.
  Future<List<ListingModel>> fetchByAuthor(String authorId);

  /// The listing, or null. [ListingModel.hiddenDetail] is filled only when
  /// the signed-in user is the author.
  Future<ListingModel?> fetchById(String id);

  /// Stores a new listing. Local photo paths in [ListingModel.photos] are
  /// uploaded first; the returned model has the final id and photo URLs.
  Future<ListingModel> insert(ListingModel model);

  Future<void> setStatus(String id, ListingStatus status);

  Future<void> remove(String id);
}
