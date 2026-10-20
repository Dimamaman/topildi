import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../repositories/claim_repository.dart';

/// Returns the chat id opened for the accepted claimant.
@injectable
class AcceptClaim implements UseCase<String, String> {
  const AcceptClaim(this._repository);

  final ClaimRepository _repository;

  @override
  FutureEither<String> call(String params) => _repository.accept(params);
}
