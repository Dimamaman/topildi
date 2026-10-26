import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/di/firebase_module.dart';
import '../../domain/entities/app_notification.dart';
import '../models/notification_firestore.dart';
import 'notification_remote_datasource.dart';

/// `topildi_users/{uid}/notifications`, readable by its owner only.
@prod
@LazySingleton(as: NotificationRemoteDataSource)
class FirestoreNotificationDataSource implements NotificationRemoteDataSource {
  FirestoreNotificationDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// The page shows the latest ones only.
  static const _limit = 50;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirePaths.users).doc(_auth.currentUser?.uid ?? '-').collection(FirePaths.notifications);

  Query<Map<String, dynamic>> get _unread => _col.where('read', isEqualTo: false);

  @override
  Future<List<AppNotification>> fetchAll() async {
    final snap = await _col.orderBy('createdAt', descending: true).limit(_limit).get();
    return [for (final d in snap.docs) ?notificationFromFirestore(d.id, d.data())];
  }

  @override
  Stream<int> watchUnread() {
    if (_auth.currentUser == null) return Stream.value(0);
    return _unread.snapshots().map((s) => s.size);
  }

  @override
  Future<void> markAll() async {
    final snap = await _unread.get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  @override
  Future<void> mark(String id) => _col.doc(id).update({'read': true});
}
