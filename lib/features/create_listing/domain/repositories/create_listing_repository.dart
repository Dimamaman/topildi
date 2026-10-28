import '../../../../core/usecase/usecase.dart';
import '../entities/create_draft.dart';

abstract interface class CreateListingRepository {
  /// Publishes the draft and returns the new listing id.
  FutureEither<String> post(CreateDraft draft);

  /// Saves an edit of the author's listing [id]. [hiddenDetail] false keeps
  /// the stored hidden detail (it is locked once requests came in).
  FutureEither<void> update(String id, CreateDraft draft, {required bool hiddenDetail});
}
