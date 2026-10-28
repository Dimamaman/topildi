import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../repositories/claim_repository.dart';

/// Takes back the user's unanswered claim on a listing (by listing id).
@injectable
class CancelClaim implements UseCase<void, String> {
  const CancelClaim(this._repository);

  final ClaimRepository _repository;

  @override
  FutureEither<void> call(String params) => _repository.cancel(params);
}
