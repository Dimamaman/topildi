import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../claim/domain/entities/claim.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/chat.dart';
import '../datasources/chat_remote_datasource.dart';

/// Firestore shape of `topildi_chats/{claimId}`, written when the listing's
/// author accepts [claim]. Per-member fields are maps keyed by uid.
Map<String, Object?> chatToFirestore(Claim claim, ListingModel listing) {
  final author = listing.author.id, claimant = claim.claimant.id;
  return {
    'listingId': listing.id,
    'listingTitle': listing.title,
    'listingCategory': listing.category.name,
    'listingTint': listing.tint,
    'members': [author, claimant],
    // Who hands the item over: the author of a "found" listing, otherwise
    // the person who answered a "lost" one.
    'finderId': listing.type == ListingType.found ? author : claimant,
    'names': {author: listing.author.displayName, claimant: claim.claimant.displayName},
    'returnedCounts': {author: listing.author.returnedCount, claimant: claim.claimant.returnedCount},
    'lastMessage': ChatNotes.matched,
    'lastAt': FieldValue.serverTimestamp(),
    'lastSenderId': '',
    // The claimant learns about the new chat from the badge.
    'unread': {author: 0, claimant: 1},
    'readAt': <String, Object?>{},
    'returned': false,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

DateTime? _date(Object? v) => (v as Timestamp?)?.toDate();

ChatThread threadFromFirestore(String id, Map<String, dynamic> d, {required String me}) {
  final members = [for (final m in (d['members'] as List?) ?? const []) m as String];
  final other = members.firstWhere((m) => m != me, orElse: () => '');
  final names = (d['names'] as Map?) ?? const {};
  final counts = (d['returnedCounts'] as Map?) ?? const {};
  final unread = (d['unread'] as Map?) ?? const {};
  final readAt = (d['readAt'] as Map?) ?? const {};
  return ChatThread(
    id: id,
    listingId: d['listingId'] as String? ?? '',
    listingTitle: d['listingTitle'] as String? ?? '',
    listingCategory: ItemCategory.values.firstWhere((c) => c.name == d['listingCategory'], orElse: () => ItemCategory.other),
    listingTint: (d['listingTint'] as num?)?.toInt() ?? 0,
    other: PublicUser(
      id: other,
      displayName: names[other] as String? ?? '',
      returnedCount: (counts[other] as num?)?.toInt() ?? 0,
    ),
    iAmFinder: d['finderId'] == me,
    lastMessage: d['lastMessage'] as String? ?? '',
    lastAt: _date(d['lastAt']) ?? DateTime.now(),
    unread: (unread[me] as num?)?.toInt() ?? 0,
    returned: d['returned'] as bool? ?? false,
    otherReadAt: _date(readAt[other]),
  );
}

/// The "matched" and safety notes every chat starts with. They are not
/// stored: they follow from the chat's creation time.
List<ChatMessage> openingNotes(String chatId, DateTime createdAt) => [
  ChatMessage(id: '${chatId}_m', text: ChatNotes.matched, sentAt: createdAt, kind: MessageKind.matched),
  ChatMessage(id: '${chatId}_s', text: ChatNotes.safety, sentAt: createdAt, kind: MessageKind.safety),
];

/// `topildi_chats/{id}/messages/{mid}`.
Map<String, Object?> messageToFirestore({required String senderId, required String text, MessageKind kind = MessageKind.text}) => {
  'senderId': senderId,
  'text': text,
  'kind': kind.name,
  'createdAt': FieldValue.serverTimestamp(),
};

ChatMessage messageFromFirestore(String id, Map<String, dynamic> d, {required String me}) => ChatMessage(
  id: id,
  text: d['text'] as String? ?? '',
  // My own message reads as null until the server has stamped it.
  sentAt: _date(d['createdAt']) ?? DateTime.now(),
  fromMe: d['senderId'] == me,
  kind: d['kind'] == MessageKind.returned.name ? MessageKind.returned : MessageKind.text,
);
