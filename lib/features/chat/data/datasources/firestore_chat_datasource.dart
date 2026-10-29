import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/di/firebase_module.dart';
import '../../../../core/error/failure.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/chat.dart';
import '../models/chat_firestore.dart';
import 'chat_remote_datasource.dart';

/// Chats in Firestore (`topildi_chats/{claimId}`, messages in
/// `.../messages/{id}`), readable by their two members only. See [FirePaths].
@prod
@LazySingleton(as: ChatRemoteDataSource)
class FirestoreChatDataSource implements ChatRemoteDataSource {
  FirestoreChatDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(FirePaths.chats);
  CollectionReference<Map<String, dynamic>> _messages(String id) => _col.doc(id).collection('messages');
  String get _uid => _auth.currentUser?.uid ?? '';

  ChatThread _thread(DocumentSnapshot<Map<String, dynamic>> doc) => threadFromFirestore(doc.id, doc.data()!, me: _uid);

  @override
  Stream<List<ChatThread>> watchThreads() => _col
      .where('members', arrayContains: _uid)
      .orderBy('lastAt', descending: true)
      .snapshots()
      .map((snap) => [for (final d in snap.docs) threadFromFirestore(d.id, d.data(), me: _uid)]);

  @override
  Future<ChatThread?> fetchThread(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? _thread(doc) : null;
  }

  @override
  Stream<ChatThread> watchThread(String id) =>
      _col.doc(id).snapshots().map((doc) => doc.exists ? _thread(doc) : throw const NotFoundFailure());

  @override
  Stream<List<ChatMessage>> watchMessages(String id) async* {
    final chat = await _col.doc(id).get();
    if (!chat.exists) throw const NotFoundFailure();
    final createdAt = (chat.data()!['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final notes = openingNotes(id, createdAt);
    yield* _messages(id)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => [...notes, for (final d in snap.docs) messageFromFirestore(d.id, d.data(), me: _uid)]);
  }

  /// The other member of the chat, from its `members` list.
  Future<String> _other(String id) async {
    final members = ((await _col.doc(id).get()).data()?['members'] as List?) ?? const [];
    return members.cast<String>().firstWhere((m) => m != _uid, orElse: () => throw const NotFoundFailure());
  }

  @override
  Future<ChatMessage> addMessage(String id, String text) async {
    final other = await _other(id);
    final ref = _messages(id).doc();
    final batch = _db.batch()
      ..set(ref, messageToFirestore(senderId: _uid, text: text))
      ..update(_col.doc(id), {
        'lastMessage': text,
        'lastAt': FieldValue.serverTimestamp(),
        'lastSenderId': _uid,
        'unread.$other': FieldValue.increment(1),
      });
    await batch.commit();
    return ChatMessage(id: ref.id, text: text, sentAt: DateTime.now(), fromMe: true);
  }

  @override
  Future<void> markRead(String id) =>
      _col.doc(id).update({'unread.$_uid': 0, 'readAt.$_uid': FieldValue.serverTimestamp()});

  @override
  Future<void> markReturned(String id) async {
    final doc = await _col.doc(id).get();
    final t = _thread(doc);
    if (t.returned) return;
    final listing = _db.collection(FirePaths.listings).doc(t.listingId);
    // The author may have closed the listing already from its own page.
    final listingOpen = (await listing.get()).data()?['status'] == ListingStatus.active.name;
    final batch = _db.batch()
      ..set(
        _messages(id).doc(),
        messageToFirestore(senderId: _uid, text: ChatNotes.returned, kind: MessageKind.returned),
      )
      ..update(_col.doc(id), {
        'returned': true,
        'returnedAt': FieldValue.serverTimestamp(),
        'lastMessage': ChatNotes.returned,
        'lastAt': FieldValue.serverTimestamp(),
        'lastSenderId': _uid,
        'unread.${t.other.id}': FieldValue.increment(1),
      })
      ..set(_db.collection(FirePaths.users).doc(_uid), {
        'returnedCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    if (listingOpen) {
      // The finder may not be the listing's author ("lost" listings): the
      // rules accept the status change because this chat names them finder.
      batch.update(listing, {
        'status': ListingStatus.returned.name,
        'returnedViaChat': id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<String?> ownerNote(String id) async {
    final doc = await _col.doc(id).get();
    final returnedAt = doc.data()?['returnedAt'] as Timestamp?;
    if (returnedAt == null) return null;
    final owner = doc.data()!['finderId'] == _uid ? await _other(id) : _uid;
    final snap = await _messages(id).orderBy('createdAt', descending: true).limit(20).get();
    for (final d in snap.docs) {
      final m = d.data();
      final at = m['createdAt'] as Timestamp?;
      if (at != null && at.compareTo(returnedAt) > 0 && m['senderId'] == owner && m['kind'] == MessageKind.text.name) {
        return m['text'] as String?;
      }
    }
    return null;
  }

  @override
  Future<int> myReturnedCount() async {
    final doc = await _db.collection(FirePaths.users).doc(_uid).get();
    return (doc.data()?['returnedCount'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<({DateTime? returnedAt, String? photo})> returnedItem(String id) async {
    final chat = (await _col.doc(id).get()).data();
    final listingId = chat?['listingId'] as String?;
    final listing = listingId == null ? null : (await _db.collection(FirePaths.listings).doc(listingId).get()).data();
    final photos = (listing?['photoUrls'] as List?) ?? const [];
    return (
      returnedAt: (chat?['returnedAt'] as Timestamp?)?.toDate(),
      photo: photos.isEmpty ? null : photos.first as String?,
    );
  }
}
