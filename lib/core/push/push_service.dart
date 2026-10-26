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

/// Push notifications (sent by `functions/`). This device's Firebase
/// Installation ID is stored in `topildi_users/{uid}/devices/{fid}` with the
/// interface language, so each push arrives in the language the app is in.
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
  String? _fid;
  bool _initialHandled = false;

  bool get _wanted => _kv.getBool(StoreKeys.notificationsOn) ?? true;

  DocumentReference<Map<String, dynamic>>? _device(String fid) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection(FirePaths.users).doc(uid).collection(FirePaths.devices).doc(fid);
  }

  Future<void> _save(String fid) async {
    _fid = fid;
    await _device(fid)?.set({
      'fid': fid,
      'platform': defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
      'lang': AppLanguage.current.code,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> start() async {
    if (_subs.isNotEmpty || !_wanted || _auth.currentUser == null) return;
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      _subs
        // Fires once registration completes, and again if the FID changes.
        ..add(_messaging.onRegistered.listen((fid) => _save(fid).catchError(_log)))
        // The push language follows the interface language.
        ..add(_language.stream.listen((_) => _fid == null ? null : _save(_fid!).catchError(_log)));
      await _messaging.register();
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
      if (_fid case final fid?) await _device(fid)?.delete();
      await _messaging.unregister();
    } catch (e) {
      _log(e);
    }
    _fid = null;
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
