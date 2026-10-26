// The FID API (register / onRegistered) that replaces FCM tokens fails with
// "invalid-request" on the current Firebase iOS SDK, so tokens it is.
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../di/firebase_module.dart';
import '../l10n/app_language.dart';
import '../l10n/language_cubit.dart';
import '../storage/stores.dart';

/// Push notifications (sent by `functions/`). This device's FCM token is
/// stored in `topildi_users/{uid}/devices/{token}` with the interface
/// language, so each push arrives in the language the app is in.
///
/// [FirebasePushService] in the app, [NoopPushService] in widget tests.
abstract interface class PushService {
  /// Registers this device while the Profil switch is on; asks for iOS
  /// permission the first time. Never throws.
  Future<void> start();

  /// Unregisters this device (switch turned off, before sign-out).
  Future<void> stop();

  /// App routes of tapped pushes, including the one that launched the app.
  Stream<String> get opened;

  /// While a chat is on screen its messages are already visible there:
  /// banners are muted until it closes.
  void setChatOpen(bool open);
}

@prod
@LazySingleton(as: PushService)
class FirebasePushService implements PushService {
  FirebasePushService(this._messaging, this._db, this._auth, this._kv, this._language);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final KeyValueStore _kv;
  final LanguageCubit _language;

  final _subs = <StreamSubscription<Object?>>[];
  String? _token;
  bool _initialHandled = false;

  bool get _wanted => _kv.getBool(StoreKeys.notificationsOn) ?? true;

  DocumentReference<Map<String, dynamic>>? _device(String token) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection(FirePaths.users).doc(uid).collection(FirePaths.devices).doc(token);
  }

  Future<void> _save(String token) async {
    _token = token;
    await _device(token)?.set({
      'token': token,
      'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
      'lang': AppLanguage.current.code,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// iOS hands out an FCM token only once APNs has given the device one.
  Future<bool> _apnsReady() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return true;
    for (var i = 0; i < 20; i++) {
      if (await _messaging.getAPNSToken() != null) return true;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  @override
  Future<void> start() async {
    if (_subs.isNotEmpty || !_wanted || _auth.currentUser == null) return;
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      if (!await _apnsReady()) return _log('no APNs token');
      final token = await _messaging.getToken();
      if (token == null) return _log('no FCM token');
      await _save(token);
      // Only once registered: a failed start is retried on the next one.
      _subs
        ..add(_messaging.onTokenRefresh.listen((t) => _save(t).catchError(_log)))
        // The push language follows the interface language.
        ..add(_language.stream.listen((_) => _token == null ? null : _save(_token!).catchError(_log)));
    } catch (e) {
      _log(e);
    }
  }

  @override
  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    try {
      if (_token case final token?) await _device(token)?.delete();
      await _messaging.deleteToken();
    } catch (e) {
      _log(e);
    }
    _token = null;
  }

  static String? _route(RemoteMessage? m) {
    final r = m?.data['route'];
    return r is String && r.startsWith('/') ? r : null;
  }

  @override
  Stream<String> get opened async* {
    if (!_initialHandled) {
      _initialHandled = true;
      if (_route(await _messaging.getInitialMessage()) case final r?) yield r;
    }
    yield* FirebaseMessaging.onMessageOpenedApp.map(_route).where((r) => r != null).cast<String>();
  }

  @override
  void setChatOpen(bool open) {
    if (_subs.isEmpty) return;
    _messaging
        .setForegroundNotificationPresentationOptions(alert: !open, badge: true, sound: !open)
        .catchError(_log);
  }

  static void _log(Object e) => debugPrint('Push: $e');
}

/// Widget tests: no Firebase, no pushes.
@test
@LazySingleton(as: PushService)
class NoopPushService implements PushService {
  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Stream<String> get opened => const Stream.empty();

  @override
  void setChatOpen(bool open) {}
}
