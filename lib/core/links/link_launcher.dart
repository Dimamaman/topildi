import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link outside the app (Telegram for sign-in).
abstract interface class LinkLauncher {
  /// False when nothing could open [url].
  Future<bool> open(Uri url);
}

@prod
@LazySingleton(as: LinkLauncher)
class UrlLinkLauncher implements LinkLauncher {
  @override
  Future<bool> open(Uri url) async {
    if (kDebugMode) {
      // The simulator has no Telegram: the link goes to the console and the
      // clipboard, to open in Telegram on the Mac or a phone.
      debugPrint('Opening link: $url');
      Clipboard.setData(ClipboardData(text: url.toString())).ignore();
    }
    try {
      // t.me opens the Telegram app when installed, the web page otherwise.
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

/// Widget tests: records the links instead of leaving the app.
@test
@LazySingleton(as: LinkLauncher)
class RecordingLinkLauncher implements LinkLauncher {
  final opened = <Uri>[];

  /// Set to false to test the "Telegram could not be opened" path.
  bool succeeds = true;

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return succeeds;
  }
}
