import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/phone_number.dart';
import '../repositories/auth_repository.dart';

@injectable
class SignInWithGoogle implements UseCase<AuthResult, NoParams> {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  @override
  FutureEither<AuthResult> call(NoParams params) => _repository.signInWithGoogle();
}
