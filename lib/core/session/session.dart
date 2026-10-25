import 'package:characters/characters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../media/app_dirs.dart';
import '../storage/stores.dart';

/// Signed-in user. Profile fields (name, avatar) are cached in
/// [KeyValueStore]; the phone number only in [SecureStore], and never on
/// public entities.
///
/// [FirebaseSession] in the app, [LocalSession] in widget tests.
abstract class Session {
  Session(this.kv, this.secure);

  final KeyValueStore kv;
  final SecureStore secure;

  String get userId;
  bool get signedIn;
  DateTime get memberSince;

  /// Name shown before a profile is saved (tests keep a demo name).
  String get fallbackFirstName => '';

  bool get onboardingSeen => kv.getBool(StoreKeys.onboardingSeen) ?? false;
  String get firstName => kv.getString(StoreKeys.firstName) ?? fallbackFirstName;
  String get lastName => kv.getString(StoreKeys.lastName) ?? '';

  Future<void> markOnboardingSeen() => kv.setBool(StoreKeys.onboardingSeen, true);

  Future<void> signIn({String? phone});
  Future<void> signOut();

  /// Profile photo: a local path (tests) or a download URL (Firebase).
  String? get avatarPath;
  Future<void> setAvatar(String? pathOrUrl);

  Future<void> setName(String first, String last) async {
    await kv.setString(StoreKeys.firstName, first);
    await kv.setString(StoreKeys.lastName, last);
  }

  /// Letter-avatar colour: 0 primary, 1 green, 2 peach, 3 yellow.
  int get avatarTone => int.tryParse(kv.getString(StoreKeys.avatarTone) ?? '') ?? 0;

  /// Emoji avatar, if chosen instead of a photo.
  String? get avatarEmoji => kv.getString(StoreKeys.avatarEmoji);

  Future<void> setAvatarStyle({required int tone, String? emoji}) async {
    await kv.setString(StoreKeys.avatarTone, '$tone');
    emoji == null ? await kv.remove(StoreKeys.avatarEmoji) : await kv.setString(StoreKeys.avatarEmoji, emoji);
  }

  /// Public name: first name + surname initial, e.g. "Malika K.".
  String get displayName => publicName(firstName, lastName);

  static String publicName(String first, String last) {
    final f = first.trim();
    final l = last.trim();
    return l.isEmpty ? f : '$f ${l.characters.first.toUpperCase()}.';
  }

  /// Forgets the cached profile (on sign-out).
  Future<void> clearProfile() async {
    for (final k in [StoreKeys.firstName, StoreKeys.lastName, StoreKeys.avatarPath, StoreKeys.avatarTone, StoreKeys.avatarEmoji]) {
      await kv.remove(k);
    }
  }
}

/// Real session: identity from Firebase Auth; signed in once a profile
/// (first name) has been saved or loaded for that account.
@prod
@LazySingleton(as: Session)
class FirebaseSession extends Session {
  FirebaseSession(super.kv, super.secure, this._auth, this._google);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  @override
  String get userId => _auth.currentUser?.uid ?? '';

  @override
  bool get signedIn => _auth.currentUser != null && firstName.trim().isNotEmpty;

  @override
  DateTime get memberSince => _auth.currentUser?.metadata.creationTime ?? DateTime.now();

  @override
  Future<void> signIn({String? phone}) async {
    if (phone != null) await secure.write(StoreKeys.phone, phone);
  }

  @override
  String? get avatarPath => kv.getString(StoreKeys.avatarPath);

  @override
  Future<void> setAvatar(String? pathOrUrl) =>
      pathOrUrl == null ? kv.remove(StoreKeys.avatarPath) : kv.setString(StoreKeys.avatarPath, pathOrUrl);

  @override
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Not signed in with Google.
    }
    await _auth.signOut();
    await clearProfile();
    await secure.delete(StoreKeys.phone);
  }
}

/// In-memory session for widget tests: fixed user id, demo name.
@test
@LazySingleton(as: Session)
class LocalSession extends Session {
  LocalSession(super.kv, super.secure, this._dirs);

  final AppDirs _dirs;

  @override
  String get userId => 'u_me';

  @override
  String get fallbackFirstName => 'Dilshod';

  @override
  String get lastName => kv.getString(StoreKeys.lastName) ?? 'Aliyev';

  @override
  bool get signedIn => kv.getBool(StoreKeys.signedIn) ?? false;

  @override
  DateTime get memberSince => DateTime(2026, 9);

  @override
  Future<void> signIn({String? phone}) async {
    await kv.setBool(StoreKeys.signedIn, true);
    if (phone != null) await secure.write(StoreKeys.phone, phone);
    await secure.write(StoreKeys.authToken, 'mock-token-${DateTime.now().millisecondsSinceEpoch}');
  }

  @override
  String? get avatarPath {
    final name = kv.getString(StoreKeys.avatarPath);
    return name == null ? null : _dirs.resolve(name);
  }

  @override
  Future<void> setAvatar(String? pathOrUrl) =>
      pathOrUrl == null ? kv.remove(StoreKeys.avatarPath) : kv.setString(StoreKeys.avatarPath, _dirs.nameOf(pathOrUrl));

  @override
  Future<void> signOut() async {
    await kv.setBool(StoreKeys.signedIn, false);
    await secure.delete(StoreKeys.phone);
    await secure.delete(StoreKeys.authToken);
  }
}
