import 'package:injectable/injectable.dart';

abstract interface class NetworkInfo {
  Future<bool> get isConnected;
}

/// Placeholder until a connectivity package is added: always online.
@LazySingleton(as: NetworkInfo)
class AlwaysOnlineNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}
