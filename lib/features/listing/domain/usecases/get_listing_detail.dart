import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/listing.dart';
import '../repositories/listing_repository.dart';

@injectable
class GetListingDetail implements UseCase<Listing, String> {
  const GetListingDetail(this._repository);

  final ListingRepository _repository;

  @override
  FutureEither<Listing> call(String params) => _repository.getListing(params);
}
