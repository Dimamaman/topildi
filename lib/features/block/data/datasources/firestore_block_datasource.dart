import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/di/firebase_module.dart';
import '../../domain/entities/blocked_user.dart';
import 'block_remote_datasource.dart';

/// `topildi_users/{uid}/blocked/{otherUid}`: the owner writes and reads the
/// list; the blocked person may read only their own entry (firestore.rules).
@prod
@LazySingleton(as: BlockRemoteDataSource)
class FirestoreBlockDataSource implements BlockRemoteDataSource {
  const FirestoreBlockDataSource(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String ownerId) =>
      _db.collection(FirePaths.users).doc(ownerId).collection(FirePaths.blocked);

  static BlockedUser _toEntity(QueryDocumentSnapshot<Map<String, dynamic>> d) => BlockedUser(
    id: d.id,
    name: d.data()['name'] as String? ?? '',
    // Set by the server: null for the moment between the write and its echo.
    blockedAt: (d.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Query<Map<String, dynamic>> _newestFirst(String ownerId) => _col(ownerId).orderBy('createdAt', descending: true);

  @override
  Stream<List<BlockedUser>> watch(String ownerId) =>
      _newestFirst(ownerId).snapshots().map((s) => [for (final d in s.docs) _toEntity(d)]);

  @override
  Stream<void> changes(String ownerId) => _col(ownerId).snapshots().skip(1).map((_) {});

  @override
  Future<Set<String>> idsOf(String ownerId) async =>
      {for (final d in (await _col(ownerId).get()).docs) d.id};

  @override
  Future<void> add(String ownerId, String otherUid, String name) =>
      _col(ownerId).doc(otherUid).set({'name': name, 'createdAt': FieldValue.serverTimestamp()});

  @override
  Future<void> remove(String ownerId, String otherUid) => _col(ownerId).doc(otherUid).delete();

  @override
  Future<bool> blocks(String otherUid, String me) async => (await _col(otherUid).doc(me).get()).exists;
}
