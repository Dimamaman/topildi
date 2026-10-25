import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../../domain/entities/phone_number.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase Auth (SMS code or Google) + the public profile in
/// `topildi_users/{uid}`. The phone number stays inside Firebase Auth: it is never
/// written to Firestore.
@prod
@LazySingleton(as: AuthRepository)
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._db, this._storage, this._google, this._session, this._network);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final GoogleSignIn _google;
  final Session _session;
  final NetworkInfo _network;

  String? _verificationId;
  int? _resendToken;
  bool _googleReady = false;

  DocumentReference<Map<String, dynamic>> get _me => _db.collection(FirePaths.users).doc(_auth.currentUser!.uid);

  @override
  FutureEither<void> requestCode(PhoneNumber phone) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    final sent = Completer<Either<Failure, void>>();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+998${phone.digits}',
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        codeSent: (id, token) {
          _verificationId = id;
          _resendToken = token;
          if (!sent.isCompleted) sent.complete(right(null));
        },
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
        verificationFailed: (e) {
          if (!sent.isCompleted) sent.complete(left(_authFailure(e)));
        },
        // Android-only instant verification; iOS always goes through the code.
        verificationCompleted: (credential) => _auth.signInWithCredential(credential),
      );
    } on FirebaseAuthException catch (e) {
      return left(_authFailure(e));
    }
    return sent.future;
  }

  @override
  FutureEither<AuthResult> verifyCode(PhoneNumber phone, String code) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    final id = _verificationId;
    if (id == null) return left(ValidationFailure(tr('Kod eskirdi. Yangisini oling')));
    try {
      await _auth.signInWithCredential(PhoneAuthProvider.credential(verificationId: id, smsCode: code));
      await _session.signIn(phone: phone.digits);
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
    'invalid-verification-code' => ValidationFailure(tr('Kod notoʻgʻri. Qayta tekshiring')),
    'session-expired' || 'invalid-verification-id' => ValidationFailure(tr('Kod eskirdi. Yangisini oling')),
    'invalid-phone-number' => ValidationFailure(tr('Telefon raqami notoʻgʻri')),
    'too-many-requests' || 'quota-exceeded' => ValidationFailure(tr('Juda koʻp urinish. Birozdan soʻng qayta urinib koʻring')),
    'network-request-failed' => const NetworkFailure(),
    _ => ServerFailure('${e.code}: ${e.message ?? ''}'),
  };
}
