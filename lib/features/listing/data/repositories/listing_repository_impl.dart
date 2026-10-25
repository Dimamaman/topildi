import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listing_repository.dart';
import '../../../../core/error/firebase_failure.dart';
import '../datasources/listing_remote_datasource.dart';
import '../models/listing_model.dart';

@LazySingleton(as: ListingRepository)
class ListingRepositoryImpl implements ListingRepository {
  const ListingRepositoryImpl(this._source, this._network, this._session);

  final ListingRemoteDataSource _source;
  final NetworkInfo _network;
  final Session _session;

  @override
  FutureEither<ListingPage> getListings(ListingQuery query) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final needle = query.search.trim().toLowerCase();
      final items = (await _source.fetch(query))
          .where((m) => needle.isEmpty || m.title.toLowerCase().contains(needle) || m.areaName.toLowerCase().contains(needle))
          .map((m) => m.toEntity())
          .toList();
      return right(ListingPage(items: items, total: items.length));
    } catch (e) {
      return left(failureOf(e));
    }
  }

  @override
  Stream<void> get changes => _source.changes;

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
