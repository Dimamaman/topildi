import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/di/firebase_module.dart';
import '../../../../core/media/photo_compress.dart';
import '../../domain/entities/listing.dart';
import '../models/listing_firestore.dart';
import '../models/listing_model.dart';
import 'listing_remote_datasource.dart';

/// Listings in Firestore (`topildi_listings/{id}`, hidden detail in
/// `topildi_listings/{id}/private/secret`) with photos in Storage
/// (`topildi/listings/{id}/{n}.jpg`). See [FirePaths].
@prod
@LazySingleton(as: ListingRemoteDataSource)
class FirestoreListingDataSource implements ListingRemoteDataSource {
  FirestoreListingDataSource(this._db, this._storage, this._auth);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  static const _pageSize = 100;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection(FirePaths.listings);
  DocumentReference<Map<String, dynamic>> _secret(String id) => _col.doc(id).collection('private').doc('secret');
  String get _uid => _auth.currentUser?.uid ?? '';

  /// Local writes plus remote ones: every write bumps `updatedAt`, so
  /// watching the newest `updatedAt` is enough to notice any change.
  late final StreamController<void> _changes = StreamController<void>.broadcast(
    onListen: () {
      _remote = _col
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .snapshots()
          .skip(1)
          .listen((_) => _changes.add(null), onError: (_) {});
    },
    onCancel: () => _remote?.cancel(),
  );
  StreamSubscription<void>? _remote;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<ListingModel>> fetch(ListingQuery query) async {
    final f = query.filter;
    final now = DateTime.now();
    Query<Map<String, dynamic>> q = _col
        .where('type', isEqualTo: query.type.name)
        .where('status', isEqualTo: ListingStatus.active.name)
        .where('city', isEqualTo: f.city);
    if (f.district != null) q = q.where('district', isEqualTo: f.district);
    final cats = f.categories.map((c) => c.name).toList();
    if (cats.length == 1) {
      q = q.where('category', isEqualTo: cats.first);
    } else if (cats.length > 1) {
      // whereIn takes at most 30 values; there are 9 categories.
      q = q.where('category', whereIn: cats);
    }
    q = q
        .where('happenedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(f.start(now)))
        .where('happenedAt', isLessThan: Timestamp.fromDate(f.end(now)))
        .orderBy('happenedAt', descending: true)
        .limit(_pageSize);
    final snap = await q.get();
    return [for (final d in snap.docs) listingFromFirestore(d.id, d.data())];
  }

  @override
  Future<List<ListingModel>> fetchByAuthor(String authorId) async {
    final snap = await _col.where('authorId', isEqualTo: authorId).orderBy('happenedAt', descending: true).get();
    return [for (final d in snap.docs) listingFromFirestore(d.id, d.data())];
  }

  @override
  Future<ListingModel?> fetchById(String id) async {
    final doc = await _col.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    var hidden = '';
    // Only the author may read the secret (also enforced by the rules).
    if (data['authorId'] == _uid && _uid.isNotEmpty) {
      hidden = (await _secret(id).get()).data()?['hiddenDetail'] as String? ?? '';
    }
    return listingFromFirestore(doc.id, data, hiddenDetail: hidden);
  }

  @override
  Future<ListingModel> insert(ListingModel model) async {
    final ref = _col.doc();
    final uploaded = <Reference>[];
    try {
      final urls = <String>[];
      for (var i = 0; i < model.photos.length; i++) {
        final p = model.photos[i];
        if (p.startsWith('http')) {
          urls.add(p);
          continue;
        }
        final file = _storage.ref(FirePaths.listingPhoto(ref.id, i));
        await file.putData(await compressForUpload(p), SettableMetadata(contentType: 'image/jpeg'));
        uploaded.add(file);
        urls.add(await file.getDownloadURL());
      }
      final batch = _db.batch()
        ..set(ref, listingToFirestore(model, photoUrls: urls))
        ..set(_secret(ref.id), {'hiddenDetail': model.hiddenDetail, 'authorId': model.author.id});
      await batch.commit();
      _changes.add(null);
      return model.copyWith(id: ref.id, photos: urls);
    } catch (_) {
      // Don't leave orphan photos behind a listing that was never saved.
      for (final f in uploaded) {
        unawaited(f.delete().catchError((_) {}));
      }
      rethrow;
    }
  }

  @override
  Future<ListingModel> update(ListingModel model, {String? hiddenDetail}) async {
    final ref = _col.doc(model.id);
    final old = [for (final p in (((await ref.get()).data()?['photoUrls'] as List?) ?? const [])) p as String];
    final uploaded = <Reference>[];
    try {
      final urls = <String>[];
      for (final p in model.photos) {
        if (p.startsWith('http')) {
          urls.add(p);
          continue;
        }
        final name = '${DateTime.now().microsecondsSinceEpoch}_${uploaded.length}';
        final file = _storage.ref(FirePaths.listingPhotoNamed(model.id, name));
        await file.putData(await compressForUpload(p), SettableMetadata(contentType: 'image/jpeg'));
        uploaded.add(file);
        urls.add(await file.getDownloadURL());
      }
      final batch = _db.batch()
        ..update(ref, {
          'category': model.category.name,
          'title': model.title,
          'areaName': model.areaName,
          'city': model.city,
          'district': model.district,
          'lat': model.lat,
          'lng': model.lng,
          'happenedAt': Timestamp.fromDate(model.happenedAt),
          'photoUrls': urls,
          'tint': model.tint,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      if (hiddenDetail != null) batch.update(_secret(model.id), {'hiddenDetail': hiddenDetail});
      await batch.commit();
      // Photos dropped in the edit; best-effort, the listing is saved.
      for (final url in old.where((u) => !urls.contains(u))) {
        unawaited(_storage.refFromURL(url).delete().catchError((_) {}));
      }
      _changes.add(null);
      return model.copyWith(photos: urls);
    } catch (_) {
      for (final f in uploaded) {
        unawaited(f.delete().catchError((_) {}));
      }
      rethrow;
    }
  }

  @override
  Future<void> setStatus(String id, ListingStatus status) async {
    final batch = _db.batch()
      ..update(_col.doc(id), {'status': status.name, 'updatedAt': FieldValue.serverTimestamp()});
    if (status == ListingStatus.returned && _uid.isNotEmpty) {
      batch.set(_db.collection(FirePaths.users).doc(_uid), {'returnedCount': FieldValue.increment(1)}, SetOptions(merge: true));
    }
    await batch.commit();
    _changes.add(null);
  }

  @override
  Future<void> remove(String id) async {
    // Photos first: the storage rules check the listing's author.
    try {
      final files = await _storage.ref(FirePaths.listingPhotos(id)).listAll();
      await Future.wait(files.items.map((f) => f.delete()));
    } catch (_) {
      // Photos are best-effort; the listing itself still goes.
    }
    await _secret(id).delete();
    await _col.doc(id).delete();
    _changes.add(null);
  }
}
