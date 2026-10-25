import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
}

/// Firestore collections and Storage folders of Topildi. The Firebase
/// project is shared with another app (FoodZeen, which owns `users/...`),
/// so everything of ours is namespaced.
abstract final class FirePaths {
  static const users = 'topildi_users';
  static const listings = 'topildi_listings';

  static String listingPhoto(String listingId, int i) => 'topildi/listings/$listingId/$i.jpg';
  static String listingPhotos(String listingId) => 'topildi/listings/$listingId';
  static String avatar(String uid) => 'topildi/users/$uid/avatar.jpg';
}
