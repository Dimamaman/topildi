import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/claim.dart';
import '../repositories/claim_repository.dart';

@injectable
class GetClaimTarget implements UseCase<ClaimTarget, String> {
  const GetClaimTarget(this._repository);

  final ClaimRepository _repository;

  @override
  FutureEither<ClaimTarget> call(String params) => _repository.getTarget(params);
}
