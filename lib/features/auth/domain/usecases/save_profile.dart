import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/l10n/tr.dart';

@injectable
class SaveProfile implements UseCase<void, ProfileInput> {
  const SaveProfile(this._repository);

  final AuthRepository _repository;

  @override
  FutureEither<void> call(ProfileInput params) async {
    if (params.firstName.trim().length < 2) return left(ValidationFailure(tr('Ismingizni kiriting')));
    return _repository.saveProfile(params);
  }
}
