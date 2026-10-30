import '../../domain/entities/blocked_user.dart';

/// Where blocks live: `topildi_users/{uid}/blocked/{otherUid}` in Firestore,
/// an in-memory mock in tests. The listing repository reads [idsOf] to keep
/// blocked people out of the feed, the map and search.
abstract interface class BlockRemoteDataSource {
  /// [ownerId]'s blocked list, newest first, live.
  Stream<List<BlockedUser>> watch(String ownerId);

  /// Fires whenever [ownerId]'s list changes, so lists built from it reload.
  Stream<void> changes(String ownerId);

  Future<Set<String>> idsOf(String ownerId);

  Future<void> add(String ownerId, String otherUid, String name);

  Future<void> remove(String ownerId, String otherUid);

  /// Whether [otherUid] has blocked [me]. The rules let each side read this
  /// one document, and nothing else of the other's list.
  Future<bool> blocks(String otherUid, String me);
}
