import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../listing/data/datasources/listing_mock_datasource.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/create_draft.dart';
import '../../domain/repositories/create_listing_repository.dart';

@LazySingleton(as: CreateListingRepository)
class CreateListingRepositoryImpl implements CreateListingRepository {
  const CreateListingRepositoryImpl(this._source, this._network, this._session);

  final ListingMockDataSource _source;
  final NetworkInfo _network;
  final Session _session;

  @override
  FutureEither<String> post(CreateDraft draft) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final model = ListingModel(
        id: 'l${DateTime.now().microsecondsSinceEpoch}',
        type: draft.type,
        category: draft.category!,
        title: draft.title.trim(),
        description: draft.description.trim(),
        areaName: draft.areaName!,
        happenedAt: draft.happenedAt(DateTime.now()),
        author: PublicUser(id: _session.userId, displayName: _session.displayName),
        hiddenDetail: draft.hiddenDetail.trim(),
        photoCount: draft.photoTints.isEmpty ? 1 : draft.photoTints.length,
        tint: draft.photoTints.isEmpty ? 0 : draft.photoTints.first,
      );
      final saved = await _source.insert(model);
      return right(saved.id);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }
}
