import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

/// Firebase services for the real app. Widget tests ([Environment.test])
/// never touch Firebase: they use the in-memory mock data sources.
@module
abstract class FirebaseModule {
  @prod
  @lazySingleton
  FirebaseAuth get auth => FirebaseAuth.instance;

  @prod
  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  @prod
  @lazySingleton
  FirebaseStorage get storage => FirebaseStorage.instance;

  @prod
  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn.instance;

  @prod
  @lazySingleton
  FirebaseMessaging get messaging => FirebaseMessaging.instance;

  /// Same region as functions/src/index.ts.
  @prod
  @lazySingleton
  FirebaseFunctions get functions => FirebaseFunctions.instanceFor(region: 'us-central1');
}

/// Firestore collections and Storage folders of Topildi. The Firebase
/// project is shared with another app (FoodZeen, which owns `users/...`),
/// so everything of ours is namespaced.
abstract final class FirePaths {
  static const users = 'topildi_users';

  /// Under a user: `notifications/{id}` (written by Cloud Functions) and
  /// `devices/{fcmToken}` (push targets). Both readable by the owner only.
  static const notifications = 'notifications';
  static const devices = 'devices';
  static const listings = 'topildi_listings';
  static const claims = 'topildi_claims';

  /// A chat's id is the id of the claim that opened it.
  static const chats = 'topildi_chats';

  /// Listing photos: in the author's own folder, so the storage rules check
  /// only the uid (no Firestore lookup). [name] is unique per photo.
  static String listingPhoto(String uid, String name) => 'topildi/uploads/$uid/$name.jpg';

  /// Older listings kept their photos here; still cleaned up on delete.
  static String listingPhotos(String listingId) => 'topildi/listings/$listingId';
  static String avatar(String uid) => 'topildi/users/$uid/avatar.jpg';
  static String claimProof(String claimId) => 'topildi/claims/$claimId/proof.jpg';
}
