import 'dart:io' show Platform;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../di/injection.dart';
import '../l10n/app_language.dart';

/// Lets a debug build report too: `flutter run --dart-define=ERROR_REPORT_DEBUG=true`.
const _reportInDebug = bool.fromEnvironment('ERROR_REPORT_DEBUG');

/// What one error is, for the purpose of not sending it twice: the error
/// itself plus the line it came from. The numbers inside a message (ids,
/// counts, times) are dropped, so "Listing l3 not found" and "Listing l9
/// not found" count as the same trouble.
String errorSignature(Object error, StackTrace? stack) {
  final message = error.toString().split('\n').first.replaceAll(RegExp(r'\d+'), '#');
  final frame = stack
      ?.toString()
      .split('\n')
      .map((l) => l.trim())
      .firstWhere((l) => l.isNotEmpty, orElse: () => '');
  return frame == null || frame.isEmpty ? message : '$message | $frame';
}

/// Keeps one bad frame from filling the chat: the same error waits out
/// [cooldown], and one run of the app sends at most [maxPerSession].
class ErrorThrottle {
  ErrorThrottle({this.cooldown = const Duration(minutes: 10), this.maxPerSession = 30});

  final Duration cooldown;
  final int maxPerSession;

  final _lastSent = <String, DateTime>{};
  int _sent = 0;

  int get sent => _sent;

  bool allow(String signature, DateTime now) {
    if (_sent >= maxPerSession) return false;
    final last = _lastSent[signature];
    if (last != null && now.difference(last) < cooldown) return false;
    _lastSent[signature] = now;
    _sent++;
    return true;
  }
}

/// Sends what goes wrong in the app to the developers' Telegram chat,
/// through the `topildiLogError` callable (functions/src/errors.ts) — the
/// bot token never leaves the server.
///
/// [install] catches what Flutter and the engine throw; `main.dart` wraps
/// the app in a guarded zone for the rest. Anywhere a failure is worth a
/// word even though the app carried on, call [report] with an `action`.
///
/// Nothing here may throw: a reporter that breaks the app it reports on is
/// worse than no reporter.
class TErrorReporter {
  TErrorReporter._();

  static final TErrorReporter instance = TErrorReporter._();

  final _throttle = ErrorThrottle();

  /// The page the person is on, kept current by [TopildiApp].
  String? route;

  bool _installed = false;
  bool _loadedInfo = false;
  String? _appVersion;
  String? _platform;
  String? _device;

  void install() {
    if (_installed) return;
    _installed = true;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      // The console and the red screen keep working.
      previous?.call(details);
      report(
        details.exception,
        details.stack,
        kind: 'flutter',
        action: details.context?.toDescription(),
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack, kind: 'platform');
      return true;
    };
  }

  /// Sends one error. [action] says what the app was doing in words the
  /// developer will recognise ("Shikoyat yuborish").
  Future<void> report(Object error, StackTrace? stack, {String kind = 'manual', String? action}) async {
    try {
      if (kDebugMode && !_reportInDebug) return;
      if (!_throttle.allow(errorSignature(error, stack), DateTime.now())) return;
      if (!getIt.isRegistered<FirebaseFunctions>()) return;
      await _loadInfo();
      await getIt<FirebaseFunctions>()
          .httpsCallable(
            'topildiLogError',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
          )
          .call<Map<String, dynamic>>({
            'kind': kind,
            'message': error.toString(),
            'stack': stack?.toString(),
            'route': route,
            'action': action,
            'uid': _uid,
            'appVersion': _appVersion,
            'platform': _platform,
            'device': _device,
            'language': AppLanguage.current.name,
            'release': kReleaseMode,
            'at': DateTime.now().toIso8601String(),
          });
    } catch (_) {
      // Reporting an error must never make one.
    }
  }

  String? get _uid {
    if (!getIt.isRegistered<FirebaseAuth>()) return null;
    return getIt<FirebaseAuth>().currentUser?.uid;
  }

  /// Version and device, read once and kept.
  Future<void> _loadInfo() async {
    if (_loadedInfo) return;
    _loadedInfo = true;
    try {
      final package = await PackageInfo.fromPlatform();
      _appVersion = '${package.version}+${package.buildNumber}';
      if (kIsWeb) return;
      final info = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        _platform = 'iOS ${ios.systemVersion}';
        _device = ios.utsname.machine;
      } else if (Platform.isAndroid) {
        final android = await info.androidInfo;
        _platform = 'Android ${android.version.release}';
        _device = '${android.manufacturer} ${android.model}';
      }
    } catch (_) {
      // An unknown device is still worth a report.
    }
  }
}
