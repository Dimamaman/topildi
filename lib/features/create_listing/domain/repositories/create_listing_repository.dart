import '../../../../core/usecase/usecase.dart';
import '../entities/create_draft.dart';

abstract interface class CreateListingRepository {
  /// Publishes the draft and returns the new listing id.
  FutureEither<String> post(CreateDraft draft);
}
