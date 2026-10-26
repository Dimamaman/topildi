import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/di/firebase_module.dart';
import '../../../../core/media/photo_compress.dart';
import '../../../chat/data/models/chat_firestore.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/claim.dart';
import '../models/claim_firestore.dart';
import 'claim_remote_datasource.dart';

/// Claims in Firestore (`topildi_claims/{listingId}_{uid}_{n}`), proof
/// photos in Storage (`topildi/claims/{id}/proof.jpg`). Every query filters
/// on the signed-in user, as the rules require. See [FirePaths].
@prod
@LazySingleton(as: ClaimRemoteDataSource)
class FirestoreClaimDataSource implements ClaimRemoteDataSource {
  FirestoreClaimDataSource(this._db, this._storage, this._auth);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(FirePaths.claims);
  String get _uid => _auth.currentUser?.uid ?? '';

  List<Claim> _list(QuerySnapshot<Map<String, dynamic>> snap) =>
      [for (final d in snap.docs) claimFromFirestore(d.id, d.data())];

  @override
  Future<List<Claim>> forListing(String listingId) async {
    final snap = await _col.where('listingId', isEqualTo: listingId).where('listingAuthorId', isEqualTo: _uid).get();
    // Equality filters only, so no composite index; sort here.
    return _list(snap)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Map<String, int>> pendingCountsForAuthor(String authorId) async {
    final snap = await _col
        .where('listingAuthorId', isEqualTo: authorId)
        .where('status', isEqualTo: ClaimStatus.pending.name)
        .get();
    final counts = <String, int>{};
    for (final c in _list(snap)) {
      counts[c.listingId] = (counts[c.listingId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<List<Claim>> byClaimant(String claimantId, String listingId) async {
    final snap = await _col.where('claimantId', isEqualTo: claimantId).where('listingId', isEqualTo: listingId).get();
    return _list(snap);
  }

  @override
  Future<Claim?> byId(String id) async {
    final doc = await _col.doc(id).get();
    final data = doc.data();
    return data == null ? null : claimFromFirestore(doc.id, data);
  }

  @override
  Future<Claim> add({required ListingModel listing, required PublicUser claimant, required SubmitClaimParams params}) async {
    final attempt = (await byClaimant(claimant.id, listing.id)).length + 1;
    final id = claimDocId(listing.id, claimant.id, attempt);
    Reference? proof;
    try {
      String? proofUrl;
      if (params.proofPath case final path?) {
        proof = _storage.ref(FirePaths.claimProof(id));
        await proof.putData(await compressForUpload(path), SettableMetadata(contentType: 'image/jpeg'));
        proofUrl = await proof.getDownloadURL();
      }
      final data = claimToFirestore(
        listingId: listing.id,
        listingAuthorId: listing.author.id,
        claimant: claimant,
        answer: params.answer.trim(),
        attempt: attempt,
        proofUrl: proofUrl,
      );
      await _col.doc(id).set(data);
      return claimFromFirestore(id, {...data, 'createdAt': Timestamp.now()});
    } catch (_) {
      // Don't leave a proof photo behind a claim that was never saved.
      if (proof != null) unawaited(proof.delete().catchError((_) {}));
      rethrow;
    }
  }

  @override
  Future<Claim> reject(String id) async {
    await _col.doc(id).update({'status': ClaimStatus.rejected.name, 'decidedAt': FieldValue.serverTimestamp()});
    return (await byId(id))!;
  }

  @override
  Future<String> accept(Claim claim, ListingModel listing) async {
    // One write: the rules let the chat exist only next to an accepted claim.
    final batch = _db.batch()
      ..update(_col.doc(claim.id), {'status': ClaimStatus.accepted.name, 'decidedAt': FieldValue.serverTimestamp()})
      ..set(_db.collection(FirePaths.chats).doc(claim.id), chatToFirestore(claim, listing));
    await batch.commit();
    return claim.id;
  }
}
