import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/firebase_failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../listing/data/datasources/listing_remote_datasource.dart';
import '../../../listing/data/models/listing_model.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/create_draft.dart';
import '../../domain/repositories/create_listing_repository.dart';

@LazySingleton(as: CreateListingRepository)
class CreateListingRepositoryImpl implements CreateListingRepository {
  const CreateListingRepositoryImpl(this._source, this._network, this._session);

  final ListingRemoteDataSource _source;
  final NetworkInfo _network;
  final Session _session;

  @override
  FutureEither<String> post(CreateDraft draft) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      final model = ListingModel(
        // The data source assigns the real id.
        id: 'l${DateTime.now().microsecondsSinceEpoch}',
        type: draft.type,
        category: draft.category!,
        title: draft.title.trim(),
        // Posting no longer asks for a description.
        description: '',
        areaName: draft.areaName!,
        // Only the approximate cell centre is stored publicly.
        lat: draft.point!.approximate().lat,
        lng: draft.point!.approximate().lng,
        district: draft.district!,
        happenedAt: draft.happenedAt(DateTime.now()),
        author: PublicUser(id: _session.userId, displayName: _session.displayName),
        hiddenDetail: draft.hiddenDetail.trim(),
        photoCount: draft.photos.isEmpty ? 1 : draft.photos.length,
        photos: draft.photos,
        // Placeholder colour when there is no photo: by category, as the
        // live preview card shows it while posting.
        tint: draft.category!.index,
      );
      final saved = await _source.insert(model);
      return right(saved.id);
    } catch (e) {
      return left(failureOf(e));
    }
  }
}
