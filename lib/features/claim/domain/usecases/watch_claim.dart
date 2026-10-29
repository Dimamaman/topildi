import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/claim.dart';
import '../repositories/claim_repository.dart';

/// One claim, live: the claimant watches it for the author's answer.
@injectable
class WatchClaim {
  const WatchClaim(this._repository);

  final ClaimRepository _repository;

  StreamEither<Claim> call(String claimId) => _repository.watchClaim(claimId);
}
