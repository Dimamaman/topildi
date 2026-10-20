import 'package:equatable/equatable.dart';

enum NotificationKind { newClaim, message, match, claimAccepted, returned, expiring }

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

class OpenProfile extends NotificationTarget {
  const OpenProfile();
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.text,
    required this.createdAt,
    required this.target,
    this.read = false,
  });

  final String id;
  final NotificationKind kind;
  final String text;
  final DateTime createdAt;
  final NotificationTarget target;
  final bool read;

  AppNotification markRead() =>
      AppNotification(id: id, kind: kind, text: text, createdAt: createdAt, target: target, read: true);

  @override
  List<Object?> get props => [id, kind, text, createdAt, target, read];
}
