import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}

/// Offline only when no interface is up AND a DNS probe fails. A captive portal still counts as
/// online; real requests surface that as a ServerFailure.
@prod
@LazySingleton(as: NetworkInfo)
class ConnectivityNetworkInfo implements NetworkInfo {
  ConnectivityNetworkInfo() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.any((r) => r != ConnectivityResult.none)) return true;
    } catch (_) {
      // Plugin unavailable (e.g. desktop dev run): fall through to the probe.
    }
    // connectivity_plus can report `none` on iOS while online (seen on the
    // simulator), so confirm with a quick DNS lookup before saying offline.
    return _probe();
  }

  Future<bool> _probe() async {
    try {
      final r = await InternetAddress.lookup('tile.openstreetmap.org').timeout(const Duration(seconds: 2));
      return r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

@test
@LazySingleton(as: NetworkInfo)
class AlwaysOnlineNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}
