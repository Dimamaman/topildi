import 'package:characters/characters.dart';
import 'package:injectable/injectable.dart';

import '../media/app_dirs.dart';
import '../storage/stores.dart';

/// Signed-in user. Flags and names live in [KeyValueStore]; the phone
/// number and token only in [SecureStore], and never on public entities.
@lazySingleton
class Session {
  Session(this._kv, this._secure, this._dirs);

  final KeyValueStore _kv;
  final SecureStore _secure;
  final AppDirs _dirs;

  String get userId => 'u_me';

  bool get signedIn => _kv.getBool(StoreKeys.signedIn) ?? false;
  bool get onboardingSeen => _kv.getBool(StoreKeys.onboardingSeen) ?? false;
  String get firstName => _kv.getString(StoreKeys.firstName) ?? 'Dilshod';
  String get lastName => _kv.getString(StoreKeys.lastName) ?? 'Aliyev';

  Future<void> markOnboardingSeen() => _kv.setBool(StoreKeys.onboardingSeen, true);

  Future<void> signIn({String? phone}) async {
    await _kv.setBool(StoreKeys.signedIn, true);
    if (phone != null) await _secure.write(StoreKeys.phone, phone);
    await _secure.write(StoreKeys.authToken, 'mock-token-${DateTime.now().millisecondsSinceEpoch}');
  }

  /// Local path of the profile photo, if any.
  String? get avatarPath {
    final name = _kv.getString(StoreKeys.avatarPath);
    return name == null ? null : _dirs.resolve(name);
  }

  Future<void> setName(String first, String last) async {
    await _kv.setString(StoreKeys.firstName, first);
    await _kv.setString(StoreKeys.lastName, last);
  }

  /// Letter-avatar colour: 0 primary, 1 green, 2 peach, 3 yellow.
  int get avatarTone => int.tryParse(_kv.getString(StoreKeys.avatarTone) ?? '') ?? 0;

  /// Emoji avatar, if chosen instead of a photo.
  String? get avatarEmoji => _kv.getString(StoreKeys.avatarEmoji);

  Future<void> setAvatarStyle({required int tone, String? emoji}) async {
    await _kv.setString(StoreKeys.avatarTone, '$tone');
    emoji == null ? await _kv.remove(StoreKeys.avatarEmoji) : await _kv.setString(StoreKeys.avatarEmoji, emoji);
  }

  Future<void> setAvatar(String? path) =>
      path == null ? _kv.remove(StoreKeys.avatarPath) : _kv.setString(StoreKeys.avatarPath, _dirs.nameOf(path));

  Future<void> signOut() async {
    await _kv.setBool(StoreKeys.signedIn, false);
    await _secure.delete(StoreKeys.phone);
    await _secure.delete(StoreKeys.authToken);
  }

  /// Public name: first name + surname initial, e.g. "Malika K.".
  String get displayName => publicName(firstName, lastName);

  static String publicName(String first, String last) {
    final f = first.trim();
    final l = last.trim();
    return l.isEmpty ? f : '$f ${l.characters.first.toUpperCase()}.';
  }
}
