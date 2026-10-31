import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/di/firebase_module.dart';

/// The one consent the app stores about a person: may their name be shown on
/// the items they returned. It lives on the public profile
/// (`topildi_users/{uid}.showNameOnReturns`) because Cloud Functions read it
/// there to fill, or empty, `finderDisplayName` on every returned listing.
abstract interface class ConsentRemoteDataSource {
  Future<void> setShowNameOnReturns(bool on);
}

@prod
@LazySingleton(as: ConsentRemoteDataSource)
class FirestoreConsentDataSource implements ConsentRemoteDataSource {
  FirestoreConsentDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Future<void> setShowNameOnReturns(bool on) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    await _db.collection(FirePaths.users).doc(uid).set({
      'showNameOnReturns': on,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

/// Widget tests: remembers the last value, touches no network.
@test
@LazySingleton(as: ConsentRemoteDataSource)
class MockConsentDataSource implements ConsentRemoteDataSource {
  bool showNameOnReturns = false;

  @override
  Future<void> setShowNameOnReturns(bool on) async => showNameOnReturns = on;
}
