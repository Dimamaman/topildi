import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:topildi/core/network/network_info.dart';
import 'package:topildi/core/session/session.dart';
import 'package:topildi/features/block/data/datasources/block_remote_datasource.dart';
import 'package:topildi/features/listing/data/datasources/listing_remote_datasource.dart';
import 'package:topildi/features/listing/data/repositories/listing_repository_impl.dart';
import 'package:topildi/features/listing/data/models/listing_firestore.dart';
import 'package:topildi/features/listing/data/models/listing_model.dart';
import 'package:topildi/features/listing/domain/entities/listing.dart';
import 'package:topildi/features/listing/domain/entities/returned_item.dart';

class _MockSource extends Mock implements ListingRemoteDataSource {}

class _MockBlocks extends Mock implements BlockRemoteDataSource {}

class _MockNetwork extends Mock implements NetworkInfo {}

class _MockSession extends Mock implements Session {}

/// The feed's "Egasiga qaytdi" strip: what reaches it, and what must not.
void main() {
  ListingModel model({
    ItemCategory category = ItemCategory.keys,
    ListingStatus status = ListingStatus.returned,
    DateTime? returnedAt,
  }) => ListingModel(
    id: 'l1',
    type: ListingType.found,
    category: category,
    title: 'Kalitlar',
    description: 'Koʻk brelok',
    areaName: 'Chilonzor-9, metro yonida',
    district: 'Chilonzor',
    happenedAt: DateTime(2026, 10, 1, 9),
    author: const PublicUser(id: 'u1', displayName: 'Malika K.', returnedCount: 2),
    hiddenDetail: 'Ichida qizil kalit',
    status: status,
    returnedAt: returnedAt,
  );

  group('returnedAt comes from the closing write', () {
    test('a returned listing carries the time it was closed', () {
      final back = listingFromFirestore('l1', {
        'status': 'returned',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 29, 14, 30)),
      });
      expect(back.status, ListingStatus.returned);
      expect(back.returnedAt, DateTime(2026, 10, 29, 14, 30));
    });

    test('an active listing has none, however often it was edited', () {
      final back = listingFromFirestore('l1', {
        'status': 'active',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 29, 14, 30)),
      });
      expect(back.returnedAt, isNull);
    });
  });

  group('ReturnedItem keeps the strip anonymous', () {
    test('it has no author and no street-level area to leak', () {
      final m = model(returnedAt: DateTime(2026, 10, 29));
      final item = ReturnedItem(
        id: m.id,
        title: m.title,
        category: m.category,
        district: m.district,
        returnedAt: m.returnedAt!,
        photo: null,
      );
      // The name is dropped by the entity's shape, not by the widget: there
      // is no field here that could carry it back.
      expect(item.props, isNot(contains(m.author.displayName)));
      expect(item.props, isNot(contains(m.areaName)));
      expect(item.district, 'Chilonzor');
    });
  });

  group('the finder is named only when the server wrote the name', () {
    test('finderDisplayName comes off the document', () {
      final back = listingFromFirestore('l1', {
        'status': 'returned',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 29, 14, 30)),
        'finderDisplayName': 'Dinmuhammad D.',
      });
      expect(back.finderName, 'Dinmuhammad D.');
    });

    test('without it the story carries no name at all', () {
      final back = listingFromFirestore('l1', {
        'status': 'returned',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 29, 14, 30)),
      });
      expect(back.finderName, isNull);
    });

    test('the owner is never a candidate: only the finder has a field', () {
      final back = listingFromFirestore('l1', {
        'status': 'returned',
        'authorName': 'Sardor A.',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 29, 14, 30)),
      });
      expect(back.finderName, isNull);
    });
  });

  group('ListingRepositoryImpl.getReturned', () {
    late _MockSource source;
    late _MockBlocks blocks;
    late _MockNetwork network;
    late _MockSession session;
    late ListingRepositoryImpl repo;

    ListingModel row(String id, {required ItemCategory category, String author = 'u1', DateTime? at}) =>
        ListingModel(
          id: id,
          type: ListingType.found,
          category: category,
          title: 'Buyum $id',
          description: '',
          areaName: 'Chilonzor-9, metro yonida',
          district: 'Chilonzor',
          happenedAt: DateTime(2026, 10, 1),
          author: PublicUser(id: author, displayName: 'Malika K.'),
          hiddenDetail: '',
          status: ListingStatus.returned,
          returnedAt: at ?? DateTime(2026, 10, 29),
        );

    setUp(() {
      source = _MockSource();
      blocks = _MockBlocks();
      network = _MockNetwork();
      session = _MockSession();
      repo = ListingRepositoryImpl(source, blocks, network, session);
      when(() => network.isConnected).thenAnswer((_) async => true);
      when(() => session.userId).thenReturn('u_me');
      when(() => blocks.idsOf(any())).thenAnswer((_) async => <String>{});
    });

    Future<List<ReturnedItem>> items() async =>
        (await repo.getReturned()).getOrElse((f) => throw StateError('getReturned failed: $f'));

    // A passport or a licence that found its owner must not be shown again,
    // so the whole category is dropped.
    test('documents never reach the strip', () async {
      when(() => source.fetchReturned(limit: any(named: 'limit'))).thenAnswer(
        (_) async => [
          row('a', category: ItemCategory.documents),
          row('b', category: ItemCategory.keys),
          row('c', category: ItemCategory.wallets),
        ],
      );
      expect((await items()).map((i) => i.id), ['b', 'c']);
    });

    test('a blocked author is left out, as everywhere else', () async {
      when(() => blocks.idsOf('u_me')).thenAnswer((_) async => {'u_blocked'});
      when(() => source.fetchReturned(limit: any(named: 'limit'))).thenAnswer(
        (_) async => [
          row('a', category: ItemCategory.keys, author: 'u_blocked'),
          row('b', category: ItemCategory.keys),
        ],
      );
      expect((await items()).map((i) => i.id), ['b']);
    });

    test('a listing with no return time is skipped', () async {
      when(() => source.fetchReturned(limit: any(named: 'limit'))).thenAnswer(
        (_) async => [
          ListingModel(
            id: 'a',
            type: ListingType.found,
            category: ItemCategory.keys,
            title: 'Kalit',
            description: '',
            areaName: 'Chilonzor',
            happenedAt: DateTime(2026, 10, 1),
            author: const PublicUser(id: 'u1', displayName: 'Malika K.'),
            hiddenDetail: '',
            status: ListingStatus.returned,
          ),
          row('b', category: ItemCategory.keys),
        ],
      );
      expect((await items()).map((i) => i.id), ['b']);
    });

    test('no more than the limit asked for', () async {
      when(() => source.fetchReturned(limit: any(named: 'limit')))
          .thenAnswer((_) async => [for (var i = 0; i < 20; i++) row('r$i', category: ItemCategory.keys)]);
      expect(await items(), hasLength(12));
    });

    test('the finder name reaches the strip as the document had it', () async {
      when(() => source.fetchReturned(limit: any(named: 'limit'))).thenAnswer(
        (_) async => [
          ListingModel(
            id: 'a',
            type: ListingType.found,
            category: ItemCategory.keys,
            title: 'Kalit',
            description: '',
            areaName: 'Chilonzor-9',
            district: 'Chilonzor',
            happenedAt: DateTime(2026, 10, 1),
            author: const PublicUser(id: 'u1', displayName: 'Sardor A.'),
            hiddenDetail: '',
            status: ListingStatus.returned,
            returnedAt: DateTime(2026, 10, 29),
            finderName: 'Dinmuhammad D.',
          ),
          row('b', category: ItemCategory.keys),
        ],
      );
      final list = await items();
      expect(list.first.finderName, 'Dinmuhammad D.');
      // The author's name is never used as a stand-in for a missing consent.
      expect(list.last.finderName, isNull);
    });

    test('offline fails instead of showing an empty strip', () async {
      when(() => network.isConnected).thenAnswer((_) async => false);
      expect((await repo.getReturned()).isLeft(), isTrue);
    });
  });
}
