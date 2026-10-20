import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/create_draft.dart';
import '../repositories/create_listing_repository.dart';

@injectable
class PostListing implements UseCase<String, CreateDraft> {
  const PostListing(this._repository);

  final CreateListingRepository _repository;

  @override
  FutureEither<String> call(CreateDraft params) async {
    if (!DraftValidator.isComplete(params)) {
      return left(const ValidationFailure('Eʼlon toʻliq emas'));
    }
    return _repository.post(params);
  }
}
