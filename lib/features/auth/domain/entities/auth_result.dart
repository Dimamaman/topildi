import 'package:equatable/equatable.dart';

class AuthResult extends Equatable {
  const AuthResult({required this.needsProfile});

  /// New users finish with ProfileSetup; returning users go to the feed.
  final bool needsProfile;

  @override
  List<Object?> get props => [needsProfile];
}

class ProfileInput extends Equatable {
  const ProfileInput({required this.firstName, this.lastName = '', this.photoPath, this.tone = 0, this.emoji});

  final String firstName, lastName;
  final String? photoPath;

  /// Letter-avatar colour (0 primary, 1 green, 2 peach, 3 yellow).
  final int tone;

  /// Emoji avatar instead of a photo.
  final String? emoji;

  @override
  List<Object?> get props => [firstName, lastName, photoPath, tone, emoji];
}
