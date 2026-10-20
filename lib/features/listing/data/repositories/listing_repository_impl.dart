import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listing_repository.dart';
import '../datasources/listing_mock_datasource.dart';

@LazySingleton(as: ListingRepository)
class ListingRepositoryImpl implements ListingRepository {
  const ListingRepositoryImpl(this._source, this._network);

  final ListingMockDataSource _source;
  final NetworkInfo _network;

  @override
  FutureEither<ListingPage> getListings(ListingQuery query) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final all = await _source.fetchAll();
      final needle = query.search.trim().toLowerCase();
      final f = query.filter;
      final now = DateTime.now();
      final from = f.start(now);
      final to = f.end(now);
      final items = all
          .where((m) => m.type == query.type && m.status == ListingStatus.active)
          .where((m) => f.categories.isEmpty || f.categories.contains(m.category))
          .where((m) => m.city == f.city && (f.district == null || m.district == f.district))
          .where((m) => !m.happenedAt.isBefore(from) && m.happenedAt.isBefore(to))
          .where((m) => needle.isEmpty || m.title.toLowerCase().contains(needle) || m.areaName.toLowerCase().contains(needle))
          .map((m) => m.toEntity())
          .toList();
      return right(ListingPage(items: items, total: items.length));
    } catch (e) {
      return left(ServerFailure(e.toString()));
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
      return left(ServerFailure(e.toString()));
    }
  }
}
