import 'package:equatable/equatable.dart';

import '../../../listing/domain/entities/listing.dart';

/// A chat exists only after a claim was accepted. No phone numbers anywhere.
class ChatThread extends Equatable {
  const ChatThread({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingCategory,
    required this.listingTint,
    required this.other,
    required this.iAmFinder,
    required this.lastMessage,
    required this.lastAt,
    this.unread = 0,
    this.returned = false,
  });

  final String id, listingId, listingTitle;
  final ItemCategory listingCategory;
  final int listingTint;
  final PublicUser other;

  /// True when the signed-in user found the item (can mark it returned).
  final bool iAmFinder;
  final String lastMessage;
  final DateTime lastAt;
  final int unread;
  final bool returned;

  ChatThread copyWith({String? lastMessage, DateTime? lastAt, int? unread, bool? returned}) => ChatThread(
        id: id,
        listingId: listingId,
        listingTitle: listingTitle,
        listingCategory: listingCategory,
        listingTint: listingTint,
        other: other,
        iAmFinder: iAmFinder,
        lastMessage: lastMessage ?? this.lastMessage,
        lastAt: lastAt ?? this.lastAt,
        unread: unread ?? this.unread,
        returned: returned ?? this.returned,
      );

  @override
  List<Object?> get props =>
      [id, listingId, listingTitle, listingCategory, listingTint, other, iAmFinder, lastMessage, lastAt, unread, returned];
}

enum MessageKind { text, matched, safety, returned }

class ChatMessage extends Equatable {
  const ChatMessage({required this.id, required this.text, required this.sentAt, this.fromMe = false, this.kind = MessageKind.text});

  final String id, text;
  final DateTime sentAt;
  final bool fromMe;
  final MessageKind kind;

  bool get isSystem => kind != MessageKind.text;

  @override
  List<Object?> get props => [id, text, sentAt, fromMe, kind];
}

/// Data for the thank-you screen after an item is returned.
class ReturnSummary extends Equatable {
  const ReturnSummary({
    required this.listingTitle,
    required this.finderName,
    required this.owner,
    required this.ownerNote,
    required this.returnedCount,
    required this.iAmFinder,
  });

  final String listingTitle, finderName;
  final PublicUser owner;
  final String? ownerNote;
  final int returnedCount;
  final bool iAmFinder;

  @override
  List<Object?> get props => [listingTitle, finderName, owner, ownerNote, returnedCount, iAmFinder];
}
