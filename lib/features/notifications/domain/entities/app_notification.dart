import 'package:equatable/equatable.dart';

/// What happened. Written by the server (Cloud Functions) together with the
/// push; chat messages are pushed only, the Chatlar tab lists them.
enum NotificationKind { newClaim, claimAccepted, claimRejected, returned }

/// Where tapping a notification leads.
sealed class NotificationTarget extends Equatable {
  const NotificationTarget();

  @override
  List<Object?> get props => [];
}

class OpenClaims extends NotificationTarget {
  const OpenClaims(this.listingId);
  final String listingId;
  @override
  List<Object?> get props => [listingId];
}

class OpenChat extends NotificationTarget {
  const OpenChat(this.chatId);
  final String chatId;
  @override
  List<Object?> get props => [chatId];
}

class OpenListing extends NotificationTarget {
  const OpenListing(this.listingId);
  final String listingId;
  @override
  List<Object?> get props => [listingId];
}

class OpenSuccess extends NotificationTarget {
  const OpenSuccess(this.chatId);
  final String chatId;
  @override
  List<Object?> get props => [chatId];
}

/// The text is not stored: the page builds it from [kind] and these fields
/// in the current interface language.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.listingTitle,
    required this.createdAt,
    required this.target,
    this.actorName = '',
    this.attemptsLeft = 0,
    this.read = false,
  });

  final String id;
  final NotificationKind kind;
  final String listingTitle;

  /// The other person (who accepted the claim, who returned the item).
  final String actorName;

  /// Claim attempts the claimant still has after a rejection.
  final int attemptsLeft;
  final DateTime createdAt;
  final NotificationTarget target;
  final bool read;

  AppNotification markRead() => AppNotification(
    id: id,
    kind: kind,
    listingTitle: listingTitle,
    actorName: actorName,
    attemptsLeft: attemptsLeft,
    createdAt: createdAt,
    target: target,
    read: true,
  );

  @override
  List<Object?> get props => [id, kind, listingTitle, actorName, attemptsLeft, createdAt, target, read];
}
