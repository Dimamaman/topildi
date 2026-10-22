import 'package:equatable/equatable.dart';

import '../../../listing/domain/entities/listing.dart';

class MyListing extends Equatable {
  const MyListing({required this.listing, this.pendingClaims = 0});

  final Listing listing;
  final int pendingClaims;

  @override
  List<Object?> get props => [listing, pendingClaims];
}

/// The signed-in user's own profile. Phone number is deliberately absent.
class ProfileSummary extends Equatable {
  const ProfileSummary({
    required this.displayName,
    required this.memberSince,
    required this.active,
    required this.returned,
    required this.gotBack,
    required this.notificationsOn,
    this.avatarPath,
    this.avatarTone = 0,
    this.avatarEmoji,
  });

  final String? avatarPath;

  /// Letter-avatar colour and optional emoji (see `Session`).
  final int avatarTone;
  final String? avatarEmoji;

  final String displayName;
  final DateTime memberSince;
  final List<MyListing> active, returned;

  /// Own lost items that came back.
  final int gotBack;
  final bool notificationsOn;

  int get total => active.length + returned.length;

  @override
  List<Object?> get props => [
    displayName,
    memberSince,
    active,
    returned,
    gotBack,
    notificationsOn,
    avatarPath,
    avatarTone,
    avatarEmoji,
  ];
}
