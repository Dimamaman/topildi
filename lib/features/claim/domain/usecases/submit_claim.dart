import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/claim.dart';
import '../repositories/claim_repository.dart';
import '../../../../core/l10n/tr.dart';

@injectable
class SubmitClaim implements UseCase<Claim, SubmitClaimParams> {
  const SubmitClaim(this._repository);

  final ClaimRepository _repository;

  @override
  FutureEither<Claim> call(SubmitClaimParams params) async {
    if (params.answer.trim().length < SubmitClaimParams.minAnswer) {
      return left(ValidationFailure(tr('Javobni batafsilroq yozing (kamida 10 ta belgi)')));
    }
    return _repository.submit(params);
  }
}
