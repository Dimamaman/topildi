import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:topildi/features/chat/data/models/chat_firestore.dart';
import 'package:topildi/features/chat/domain/entities/chat.dart';
import 'package:topildi/features/claim/domain/entities/claim.dart';
import 'package:topildi/features/listing/data/models/listing_model.dart';
import 'package:topildi/features/listing/domain/entities/listing.dart';

void main() {
  ListingModel listing(ListingType type) => ListingModel(
        id: 'l1',
        type: type,
        category: ItemCategory.wallets,
        title: 'Qora hamyon',
        description: '',
        areaName: 'Chilonzor',
        happenedAt: DateTime(2026, 10, 1),
        author: const PublicUser(id: 'u1', displayName: 'Dilshod A.', returnedCount: 3),
        hiddenDetail: 'Ichida chipta',
        tint: 2,
      );
  final claim = Claim(
    id: 'l1_u2_1',
    listingId: 'l1',
    claimant: const PublicUser(id: 'u2', displayName: 'Malika K.'),
    answer: 'Ichida chipta bor',
    createdAt: DateTime(2026, 10, 2),
  );

  Map<String, dynamic> stored(ListingType type) => {
        ...chatToFirestore(claim, listing(type)),
        'lastAt': Timestamp.fromDate(DateTime(2026, 10, 3)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 2)),
      };

  test('chat doc: two members, finder by listing type, no secrets', () {
    final found = chatToFirestore(claim, listing(ListingType.found));
    expect(found['members'], ['u1', 'u2']);
    expect(found['finderId'], 'u1');
    expect(chatToFirestore(claim, listing(ListingType.lost))['finderId'], 'u2');
    expect(found.values, isNot(contains('Ichida chipta')));
    expect(found.keys.any((k) => k.toLowerCase().contains('phone')), isFalse);
  });

  test('thread is seen from each member', () {
    final d = stored(ListingType.found)
      ..['readAt'] = {'u2': Timestamp.fromDate(DateTime(2026, 10, 3, 12))};
    final mine = threadFromFirestore('l1_u2_1', d, me: 'u1');
    expect(mine.other.displayName, 'Malika K.');
    expect(mine.iAmFinder, isTrue);
    expect(mine.unread, 0);
    expect(mine.otherReadAt, DateTime(2026, 10, 3, 12));
    expect(mine.listingCategory, ItemCategory.wallets);

    final theirs = threadFromFirestore('l1_u2_1', d, me: 'u2');
    expect(theirs.other.displayName, 'Dilshod A.');
    expect(theirs.other.returnedCount, 3);
    expect(theirs.iAmFinder, isFalse);
    expect(theirs.unread, 1);
    expect(theirs.otherReadAt, isNull);
    expect(theirs.lastMessage, ChatNotes.matched);
  });

  test('messages: mine vs theirs, read ticks follow the other read time', () {
    final t = threadFromFirestore(
      'c',
      stored(ListingType.found)..['readAt'] = {'u2': Timestamp.fromDate(DateTime(2026, 10, 3, 12))},
      me: 'u1',
    );
    Map<String, dynamic> msg(String sender, DateTime at) =>
        {...messageToFirestore(senderId: sender, text: 'Salom'), 'createdAt': Timestamp.fromDate(at)};
    final early = messageFromFirestore('a', msg('u1', DateTime(2026, 10, 3, 11)), me: 'u1');
    final late = messageFromFirestore('b', msg('u1', DateTime(2026, 10, 3, 13)), me: 'u1');
    final theirs = messageFromFirestore('c', msg('u2', DateTime(2026, 10, 3, 11)), me: 'u1');
    expect(early.fromMe, isTrue);
    expect(t.seen(early), isTrue);
    expect(t.seen(late), isFalse);
    expect(theirs.fromMe, isFalse);
    expect(t.seen(theirs), isFalse);
  });

  test('opening notes come first and are system messages', () {
    final notes = openingNotes('c', DateTime(2026, 10, 2));
    expect(notes.map((n) => n.kind), [MessageKind.matched, MessageKind.safety]);
    expect(notes.every((n) => n.isSystem), isTrue);
  });
}
