import 'package:equatable/equatable.dart';

/// Someone the signed-in user has blocked: they can neither write nor send a
/// "Bu meniki" request, and their listings are left out of the feed, the map
/// and search. Blocking is silent — the other side is never told.
class BlockedUser extends Equatable {
  const BlockedUser({required this.id, required this.name, required this.blockedAt});

  final String id;

  /// Their public name as it was when they were blocked, so the list reads
  /// the same even if their profile is gone.
  final String name;
  final DateTime blockedAt;

  @override
  List<Object?> get props => [id, name, blockedAt];
}
