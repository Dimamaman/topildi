import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/listing.dart';
import '../repositories/listing_repository.dart';

/// Found and lost listings together, for the map.
@injectable
class GetMapListings implements UseCase<List<Listing>, ListingFilter> {
  const GetMapListings(this._repository);

  final ListingRepository _repository;

  @override
  FutureEither<List<Listing>> call(ListingFilter params) async {
    final found = await _repository.getListings(ListingQuery(type: ListingType.found, filter: params));
    final lost = await _repository.getListings(ListingQuery(type: ListingType.lost, filter: params));
    return found.flatMap((f) => lost.map((l) => [...f.items, ...l.items]));
  }
}
