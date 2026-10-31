import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/returned_item.dart';
import '../repositories/listing_repository.dart';

/// Items recently returned to their owners, for the feed's proof strip.
@injectable
class GetReturnedItems implements UseCase<List<ReturnedItem>, NoParams> {
  const GetReturnedItems(this._repository);

  final ListingRepository _repository;

  /// Enough to fill the strip on the widest phone and still scroll a little.
  static const limit = 12;

  @override
  FutureEither<List<ReturnedItem>> call(NoParams params) => _repository.getReturned(limit: limit);
}
