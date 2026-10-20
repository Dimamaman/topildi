import 'package:equatable/equatable.dart';

/// Uzbek mobile number without the +998 prefix (9 digits).
class PhoneNumber extends Equatable {
  const PhoneNumber._(this.digits);

  static const length = 9;

  final String digits;

  /// Returns null unless [input] holds exactly 9 digits.
  static PhoneNumber? tryParse(String input) {
    final d = input.replaceAll(RegExp(r'\D'), '');
    return d.length == length ? PhoneNumber._(d) : null;
  }

  /// "+998 90 *** ** 67" — shown only to the owner on the SMS screen.
  String get masked => '+998 ${digits.substring(0, 2)} *** ** ${digits.substring(7)}';

  @override
  List<Object?> get props => [digits];
}

class AuthResult extends Equatable {
  const AuthResult({required this.needsProfile});

  /// New users finish with ProfileSetup; returning users go to the feed.
  final bool needsProfile;

  @override
  List<Object?> get props => [needsProfile];
}

class ProfileInput extends Equatable {
  const ProfileInput({required this.firstName, this.lastName = '', this.photoPath});

  final String firstName, lastName;
  final String? photoPath;

  @override
  List<Object?> get props => [firstName, lastName, photoPath];
}
