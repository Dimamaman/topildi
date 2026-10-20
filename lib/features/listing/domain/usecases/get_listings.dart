import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/listing.dart';
import '../repositories/listing_repository.dart';

@injectable
class GetListings implements UseCase<ListingPage, ListingQuery> {
  const GetListings(this._repository);

  final ListingRepository _repository;

  @override
  FutureEither<ListingPage> call(ListingQuery params) => _repository.getListings(params);
}
