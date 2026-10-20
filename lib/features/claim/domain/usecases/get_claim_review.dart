import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/claim.dart';
import '../repositories/claim_repository.dart';

@injectable
class GetClaimReview implements UseCase<ClaimReview, String> {
  const GetClaimReview(this._repository);

  final ClaimRepository _repository;

  @override
  FutureEither<ClaimReview> call(String params) => _repository.getReview(params);
}
