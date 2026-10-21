import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/listing.dart';
import '../repositories/listing_repository.dart';

@injectable
class DeleteListing implements UseCase<void, String> {
  const DeleteListing(this._repository);

  final ListingRepository _repository;

  @override
  FutureEither<void> call(String params) => _repository.delete(params);
}

@injectable
class MarkListingReturned implements UseCase<Listing, String> {
  const MarkListingReturned(this._repository);

  final ListingRepository _repository;

  @override
  FutureEither<Listing> call(String params) => _repository.markReturned(params);
}
