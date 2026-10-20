import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}

/// Treats "no interface up" as offline. A captive portal still counts as
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
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      // Plugin unavailable (e.g. desktop dev run): don't block the app.
      return true;
    }
  }
}

@test
@LazySingleton(as: NetworkInfo)
class AlwaysOnlineNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}
