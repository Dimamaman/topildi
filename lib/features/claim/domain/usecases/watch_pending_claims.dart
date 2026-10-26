import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../repositories/claim_repository.dart';

/// Pending claims per listing of the signed-in user, live.
@injectable
class WatchPendingClaims {
  const WatchPendingClaims(this._repository);

  final ClaimRepository _repository;

  StreamEither<Map<String, int>> call() => _repository.watchPendingCounts();
}
