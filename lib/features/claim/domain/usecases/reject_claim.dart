import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/claim.dart';
import '../repositories/claim_repository.dart';

@injectable
class RejectClaim implements UseCase<Claim, String> {
  const RejectClaim(this._repository);

  final ClaimRepository _repository;

  @override
  FutureEither<Claim> call(String params) => _repository.reject(params);
}
