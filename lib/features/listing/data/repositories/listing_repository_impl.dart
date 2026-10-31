import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../block/data/datasources/block_remote_datasource.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/returned_item.dart';
import '../../domain/repositories/listing_repository.dart';
import '../../../../core/error/firebase_failure.dart';
import '../datasources/listing_remote_datasource.dart';
import '../models/listing_model.dart';

@LazySingleton(as: ListingRepository)
class ListingRepositoryImpl implements ListingRepository {
  const ListingRepositoryImpl(this._source, this._blocks, this._network, this._session);

  final ListingRemoteDataSource _source;
  final BlockRemoteDataSource _blocks;
  final NetworkInfo _network;
  final Session _session;

  @override
  FutureEither<ListingPage> getListings(ListingQuery query) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final needle = query.search.trim().toLowerCase();
      // Blocked people are left out here, so the feed, the map and search
      // all lose them at once.
      final blocked = await _blockedIds();
      final items = (await _source.fetch(query))
          .where((m) => !blocked.contains(m.author.id))
          .where((m) => needle.isEmpty || m.title.toLowerCase().contains(needle) || m.areaName.toLowerCase().contains(needle))
          .map((m) => m.toEntity())
          .toList();
      return right(ListingPage(items: items, total: items.length));
    } catch (e) {
      return left(failureOf(e));
    }
  }

  /// Items whose listing was closed as returned, for the feed's strip.
  ///
  /// Two things never reach it: a blocked author's listing, as everywhere
  /// else, and anything in [ItemCategory.documents] — a passport or a
  /// licence that has found its owner must not be advertised again, however
  /// happy the ending.
  @override
  FutureEither<List<ReturnedItem>> getReturned({int limit = 12}) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final blocked = await _blockedIds();
      final items = (await _source.fetchReturned(limit: limit))
          .where((m) => m.returnedAt != null)
          .where((m) => !blocked.contains(m.author.id))
          .where((m) => m.category != ItemCategory.documents)
          .take(limit)
          .map(
            (m) => ReturnedItem(
              id: m.id,
              title: m.title,
              category: m.category,
              district: m.district,
              returnedAt: m.returnedAt!,
              photo: m.photos.isEmpty ? null : m.photos.first,
            ),
          )
          .toList();
      return right(items);
    } catch (e) {
      return left(failureOf(e));
    }
  }

  Future<Set<String>> _blockedIds() async {
    final me = _session.userId;
    if (me.isEmpty) return const {};
    try {
      return await _blocks.idsOf(me);
    } catch (_) {
      // A list we could not read never hides a listing.
      return const {};
    }
  }

  /// A listing changed, or the signed-in user blocked or unblocked someone:
  /// either way the lists built on [getListings] have to be read again.
  @override
  Stream<void> get changes {
    final me = _session.userId;
    if (me.isEmpty) return _source.changes;
    return _merge(_source.changes, _blocks.changes(me));
  }

  @override
  FutureEither<Listing> getListing(String id) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final model = await _source.fetchById(id);
      if (model == null) return left(const NotFoundFailure());
      return right(model.toEntity());
    } catch (e) {
      return left(failureOf(e));
    }
  }

  @override
  FutureEither<void> delete(String id) => _own(id, (m) => _source.remove(m.id));

  @override
  FutureEither<Listing> markReturned(String id) => _own(id, (m) async {
        await _source.setStatus(m.id, ListingStatus.returned);
        return m.copyWith(status: ListingStatus.returned).toEntity();
      });

  /// Runs [action] on the listing only when the signed-in user wrote it.
  FutureEither<T> _own<T>(String id, Future<T> Function(ListingModel m) action) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final model = await _source.fetchById(id);
      if (model == null) return left(const NotFoundFailure());
      if (model.author.id != _session.userId) return left(const ForbiddenFailure());
      return right(await action(model));
    } catch (e) {
      return left(failureOf(e));
    }
  }
}

/// Two "something changed" streams as one, without pulling in a package.
Stream<void> _merge(Stream<void> a, Stream<void> b) {
  final subs = <StreamSubscription<void>>[];
  late final StreamController<void> c;
  c = StreamController<void>(
    onListen: () => subs.addAll([
      a.listen(c.add, onError: c.addError),
      b.listen(c.add, onError: c.addError),
    ]),
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
      subs.clear();
    },
  );
  return c.stream;
}
