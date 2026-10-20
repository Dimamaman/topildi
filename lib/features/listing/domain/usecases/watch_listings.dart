import 'package:injectable/injectable.dart';

import '../repositories/listing_repository.dart';

@injectable
class WatchListings {
  const WatchListings(this._repository);

  final ListingRepository _repository;

  Stream<void> call() => _repository.changes;
}
