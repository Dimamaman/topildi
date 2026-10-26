import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/di/firebase_module.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/firebase_failure.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/media/photo_compress.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../firebase_options.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/telegram_login.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase Auth (Telegram bot or Google) + the public profile in
/// `topildi_users/{uid}`. The phone number stays inside Firebase Auth: it is never
/// written to Firestore.
@prod
@LazySingleton(as: AuthRepository)
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._db, this._storage, this._functions, this._google, this._session, this._network);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final GoogleSignIn _google;
  final Session _session;
  final NetworkInfo _network;

  bool _googleReady = false;

  DocumentReference<Map<String, dynamic>> get _me => _db.collection(FirePaths.users).doc(_auth.currentUser!.uid);

  /// functions/src/login.ts: the session lives on the server, the app
  /// keeps only the secret that claims it.
  @override
  FutureEither<TelegramLogin> startTelegram() async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final r = await _functions.httpsCallable('topildiTgStart').call<Map<String, dynamic>>();
      final d = r.data;
      return right(TelegramLogin(sid: d['sid'] as String, secret: d['secret'] as String, url: Uri.parse(d['url'] as String)));
    } catch (e) {
      return left(failureOf(e));
    }
  }

  @override
  FutureEither<AuthResult?> claimTelegram(TelegramLogin login) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final r = await _functions
          .httpsCallable('topildiTgClaim')
          .call<Map<String, dynamic>>({'sid': login.sid, 'secret': login.secret});
      final d = r.data;
      if (d['status'] != 'verified') return right(null);
      await _auth.signInWithCustomToken(d['token'] as String);
      // "+998901234567" → the 9 digits the session keeps.
      await _session.signIn(phone: (d['phone'] as String).substring(4));
      return right(await _loadProfile());
    } on FirebaseAuthException catch (e) {
      return left(_authFailure(e));
    } catch (e) {
      return left(failureOf(e));
    }
  }

  @override
  FutureEither<AuthResult> signInWithGoogle() async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      if (!_googleReady) {
        await _google.initialize(clientId: DefaultFirebaseOptions.currentPlatform.iosClientId);
        _googleReady = true;
      }
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      return right(await _loadProfile());
    } on GoogleSignInException catch (e) {
      // Closing the Google sheet is not an error worth a message.
      return left(ValidationFailure(e.code == GoogleSignInExceptionCode.canceled ? null : tr('Kirishda xatolik yuz berdi')));
    } on FirebaseAuthException catch (e) {
      return left(_authFailure(e));
    } catch (e) {
      return left(failureOf(e));
    }
  }

  /// Returning users get their profile cached; new ones go to ProfileSetup.
  Future<AuthResult> _loadProfile() async {
    final data = (await _me.get()).data();
    final first = data?['firstName'] as String? ?? '';
    if (first.trim().isEmpty) return const AuthResult(needsProfile: true);
    await _session.setName(first, '');
    await _session.setAvatar(data?['avatarUrl'] as String?);
    await _session.setAvatarStyle(tone: (data?['avatarTone'] as num?)?.toInt() ?? 0, emoji: data?['avatarEmoji'] as String?);
    return const AuthResult(needsProfile: false);
  }

  @override
  FutureEither<void> saveProfile(ProfileInput input) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final uid = _auth.currentUser!.uid;
      final avatar = _storage.ref(FirePaths.avatar(uid));
      String? avatarUrl;
      final path = input.photoPath;
      if (path == null) {
        await avatar.delete().catchError((_) {});
      } else if (path.startsWith('http')) {
        avatarUrl = path;
      } else {
        await avatar.putData(await compressForUpload(path), SettableMetadata(contentType: 'image/jpeg'));
        avatarUrl = await avatar.getDownloadURL();
      }
      final emoji = avatarUrl == null ? input.emoji : null;
      final exists = (await _me.get()).exists;
      await _me.set({
        'firstName': input.firstName.trim(),
        'avatarUrl': avatarUrl,
        'avatarEmoji': emoji,
        'avatarTone': input.tone,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!exists) 'createdAt': FieldValue.serverTimestamp(),
        if (!exists) 'returnedCount': 0,
      }, SetOptions(merge: true));
      await _session.setName(input.firstName.trim(), '');
      await _session.setAvatar(avatarUrl);
      await _session.setAvatarStyle(tone: input.tone, emoji: emoji);
      return right(null);
    } catch (e) {
      return left(failureOf(e));
    }
  }

  static Failure _authFailure(FirebaseAuthException e) {
    // The generic message hides the cause; keep it in the log for setup problems.
    debugPrint('FirebaseAuth error: ${e.code}: ${e.message}');
    return _mapAuthFailure(e);
  }

  static Failure _mapAuthFailure(FirebaseAuthException e) => switch (e.code) {
    'too-many-requests' || 'quota-exceeded' => ValidationFailure(tr('Juda koʻp urinish. Birozdan soʻng qayta urinib koʻring')),
    'network-request-failed' => const NetworkFailure(),
    _ => ServerFailure('${e.code}: ${e.message ?? ''}'),
  };
}
