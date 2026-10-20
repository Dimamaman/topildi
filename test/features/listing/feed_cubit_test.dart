import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:topildi/core/error/failure.dart';
import 'package:topildi/core/view_state.dart';
import 'package:topildi/features/listing/domain/entities/listing.dart';
import 'package:topildi/features/listing/domain/repositories/listing_repository.dart';
import 'package:topildi/features/listing/domain/usecases/get_listings.dart';
import 'package:topildi/features/listing/domain/usecases/watch_listings.dart';
import 'package:topildi/features/listing/presentation/cubit/feed_cubit.dart';

class _MockRepo extends Mock implements ListingRepository {}

FeedCubit _cubit(_MockRepo repo) => FeedCubit(GetListings(repo), WatchListings(repo));

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
}
