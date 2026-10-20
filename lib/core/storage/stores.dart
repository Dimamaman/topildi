import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-sensitive settings (onboarding flag, theme, names).
abstract interface class KeyValueStore {
  String? getString(String key);
  bool? getBool(String key);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}

/// Sensitive values (phone number, auth token): Keychain / Android Keystore.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

@module
abstract class StorageModule {
  @prod
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @prod
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();
}

@prod
@LazySingleton(as: KeyValueStore)
class PrefsKeyValueStore implements KeyValueStore {
  const PrefsKeyValueStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  bool? getBool(String key) => _prefs.getBool(key);
  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

@prod
@LazySingleton(as: SecureStore)
class DeviceSecureStore implements SecureStore {
  const DeviceSecureStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory stores for widget tests.
@test
@LazySingleton(as: KeyValueStore)
class MemoryKeyValueStore implements KeyValueStore {
  final _data = <String, Object>{};

  @override
  String? getString(String key) => _data[key] as String?;
  @override
  bool? getBool(String key) => _data[key] as bool?;
  @override
  Future<void> setString(String key, String value) async => _data[key] = value;
  @override
  Future<void> setBool(String key, bool value) async => _data[key] = value;
  @override
  Future<void> remove(String key) async => _data.remove(key);
}

@test
@LazySingleton(as: SecureStore)
class MemorySecureStore implements SecureStore {
  final _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
}

abstract final class StoreKeys {
  static const onboardingSeen = 'onboarding_seen';
  static const signedIn = 'signed_in';
  static const firstName = 'first_name';
  static const lastName = 'last_name';
  static const avatarPath = 'avatar_path';
  static const themeMode = 'theme_mode';
  static const notificationsOn = 'notifications_on';
  static const phone = 'phone';
  static const authToken = 'auth_token';
}
