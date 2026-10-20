import 'package:characters/characters.dart';
import 'package:injectable/injectable.dart';

/// Signed-in user (in memory until a backend and secure storage exist).
/// The phone number stays here and is never exposed on public entities.
@lazySingleton
class Session {
  String get userId => 'u_me';

  bool signedIn = false;
  bool onboardingSeen = false;
  String? phone;
  String firstName = 'Dilshod';
  String lastName = 'Aliyev';

  /// Public name: first name + surname initial, e.g. "Malika K.".
  String get displayName => publicName(firstName, lastName);

  static String publicName(String first, String last) {
    final f = first.trim();
    final l = last.trim();
    return l.isEmpty ? f : '$f ${l.characters.first.toUpperCase()}.';
  }
}
