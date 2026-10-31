import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:topildi/core/error/failure.dart';
import 'package:topildi/core/view_state.dart';
import 'package:topildi/features/listing/domain/entities/listing.dart';
import 'package:topildi/features/listing/domain/repositories/listing_repository.dart';
import 'package:topildi/features/listing/domain/entities/returned_item.dart';
import 'package:topildi/features/listing/domain/usecases/get_listings.dart';
import 'package:topildi/features/listing/domain/usecases/get_returned_items.dart';
import 'package:topildi/features/listing/domain/usecases/watch_listings.dart';
import 'package:topildi/features/listing/presentation/cubit/feed_cubit.dart';

class _MockRepo extends Mock implements ListingRepository {}

FeedCubit _cubit(_MockRepo repo) => FeedCubit(GetListings(repo), GetReturnedItems(repo), WatchListings(repo));

final _loading = isA<FeedState>().having((s) => s.view, 'view', isA<ViewLoading<ListingPage>>());

void main() {
  late _MockRepo repo;
  final listing = Listing(
    id: 'x',
    type: ListingType.found,
    category: ItemCategory.keys,
    title: 'Kalit',
    description: '',
    areaName: 'Chilonzor',
    happenedAt: DateTime(2026, 10, 20),
    author: const PublicUser(id: 'u', displayName: 'Aziz T.'),
  );

  setUpAll(() => registerFallbackValue(const ListingQuery(type: ListingType.found)));
  setUp(() {
    repo = _MockRepo();
    when(() => repo.changes).thenAnswer((_) => const Stream.empty());
    when(() => repo.getReturned(limit: any(named: 'limit'))).thenAnswer((_) async => right(const []));
  });

  blocTest<FeedCubit, FeedState>(
    'emits loaded when listings exist',
    setUp: () => when(() => repo.getListings(any()))
        .thenAnswer((_) async => right(ListingPage(items: [listing], total: 1))),
    build: () => _cubit(repo),
    act: (c) => c.load(),
    expect: () => [
      _loading,
      isA<FeedState>().having((s) => s.view, 'view', isA<ViewLoaded<ListingPage>>()),
    ],
  );

  blocTest<FeedCubit, FeedState>(
    'emits empty when no listings',
    setUp: () => when(() => repo.getListings(any()))
        .thenAnswer((_) async => right(const ListingPage(items: [], total: 0))),
    build: () => _cubit(repo),
    act: (c) => c.load(),
    expect: () => [_loading, isA<FeedState>().having((s) => s.view, 'view', isA<ViewEmpty<ListingPage>>())],
  );

  blocTest<FeedCubit, FeedState>(
    'emits offline error on network failure',
    setUp: () => when(() => repo.getListings(any())).thenAnswer((_) async => left(const NetworkFailure())),
    build: () => _cubit(repo),
    act: (c) => c.load(),
    expect: () => [
      _loading,
      isA<FeedState>().having((s) => (s.view as ViewError).isOffline, 'offline', true),
    ],
  );

  blocTest<FeedCubit, FeedState>(
    'switching type reloads with the new query',
    setUp: () => when(() => repo.getListings(any()))
        .thenAnswer((_) async => right(ListingPage(items: [listing], total: 1))),
    build: () => _cubit(repo),
    act: (c) => c.setType(ListingType.lost),
    verify: (_) => verify(() => repo.getListings(const ListingQuery(type: ListingType.lost))).called(1),
  );

  ReturnedItem returnedItem(int i) => ReturnedItem(
    id: 'r$i',
    title: 'Kalit $i',
    category: ItemCategory.keys,
    district: 'Chilonzor',
    returnedAt: DateTime(2026, 10, 30 - i),
  );

  blocTest<FeedCubit, FeedState>(
    'keeps the returned strip hidden below three items',
    setUp: () {
      when(() => repo.getListings(any())).thenAnswer((_) async => right(const ListingPage(items: [], total: 0)));
      when(() => repo.getReturned(limit: any(named: 'limit')))
          .thenAnswer((_) async => right([returnedItem(1), returnedItem(2)]));
    },
    build: () => _cubit(repo),
    verify: (c) {
      expect(c.state.returned, hasLength(2));
      expect(c.state.showReturned, isFalse);
    },
  );

  blocTest<FeedCubit, FeedState>(
    'shows the returned strip from three items up',
    setUp: () {
      when(() => repo.getListings(any())).thenAnswer((_) async => right(const ListingPage(items: [], total: 0)));
      when(() => repo.getReturned(limit: any(named: 'limit')))
          .thenAnswer((_) async => right([returnedItem(1), returnedItem(2), returnedItem(3)]));
    },
    build: () => _cubit(repo),
    verify: (c) => expect(c.state.showReturned, isTrue),
  );

  blocTest<FeedCubit, FeedState>(
    'a failed strip load leaves the feed alone',
    setUp: () {
      when(() => repo.getListings(any())).thenAnswer((_) async => right(ListingPage(items: [listing], total: 1)));
      when(() => repo.getReturned(limit: any(named: 'limit')))
          .thenAnswer((_) async => left(const NetworkFailure()));
    },
    build: () => _cubit(repo),
    act: (c) => c.load(),
    expect: () => [
      _loading,
      isA<FeedState>().having((s) => s.view, 'view', isA<ViewLoaded<ListingPage>>()),
    ],
  );

  ReturnedItem returnedOf(int i, ItemCategory category) => ReturnedItem(
    id: 'c$i',
    title: 'Buyum $i',
    category: category,
    district: 'Chilonzor',
    returnedAt: DateTime(2026, 10, 30 - i),
  );

  blocTest<FeedCubit, FeedState>(
    'a category chip narrows the strip, and can hide it',
    setUp: () {
      when(() => repo.getListings(any())).thenAnswer((_) async => right(const ListingPage(items: [], total: 0)));
      when(() => repo.getReturned(limit: any(named: 'limit'))).thenAnswer(
        (_) async => right([
          returnedOf(1, ItemCategory.keys),
          returnedOf(2, ItemCategory.keys),
          returnedOf(3, ItemCategory.keys),
          returnedOf(4, ItemCategory.bags),
        ]),
      );
    },
    build: () => _cubit(repo),
    act: (c) async {
      // The constructor's load is in flight; wait for it before asserting.
      await c.loadReturned();
      expect(c.state.visibleReturned, hasLength(4));
      expect(c.state.showReturned, isTrue);
      c.setCategory(ItemCategory.keys);
      expect(c.state.showReturned, isTrue, reason: '3 ta kalit yetadi');
      // One bag is not enough to stand as proof on its own.
      c.setCategory(ItemCategory.bags);
      expect(c.state.visibleReturned, hasLength(1));
      expect(c.state.showReturned, isFalse);
    },
  );

}
