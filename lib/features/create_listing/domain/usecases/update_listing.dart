import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/create_draft.dart';
import '../repositories/create_listing_repository.dart';
import '../../../../core/l10n/tr.dart';

class UpdateListingParams {
  const UpdateListingParams({required this.id, required this.draft, required this.hiddenDetail});

  final String id;
  final CreateDraft draft;

  /// Also save the hidden detail (false once requests came in).
  final bool hiddenDetail;
}

@injectable
class UpdateListing implements UseCase<void, UpdateListingParams> {
  const UpdateListing(this._repository);

  final CreateListingRepository _repository;

  @override
  FutureEither<void> call(UpdateListingParams params) async {
    if (!DraftValidator.isComplete(params.draft)) {
      return left(ValidationFailure(tr('Eʼlon toʻliq emas')));
    }
    return _repository.update(params.id, params.draft, hiddenDetail: params.hiddenDetail);
  }
}
