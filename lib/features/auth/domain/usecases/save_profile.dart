import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/phone_number.dart';
import '../repositories/auth_repository.dart';

@injectable
class SaveProfile implements UseCase<void, ProfileInput> {
  const SaveProfile(this._repository);

  final AuthRepository _repository;

  @override
  FutureEither<void> call(ProfileInput params) async {
    if (params.firstName.trim().length < 2) return left(const ValidationFailure('Ismingizni kiriting'));
    return _repository.saveProfile(params);
  }
}
