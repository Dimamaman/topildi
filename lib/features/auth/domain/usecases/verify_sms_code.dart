import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/phone_number.dart';
import '../repositories/auth_repository.dart';

typedef VerifyParams = ({PhoneNumber phone, String code});

@injectable
class VerifySmsCode implements UseCase<AuthResult, VerifyParams> {
  const VerifySmsCode(this._repository);

  static const codeLength = 6;

  final AuthRepository _repository;

  @override
  FutureEither<AuthResult> call(VerifyParams params) async {
    if (!RegExp(r'^\d{6}$').hasMatch(params.code)) return left(const ValidationFailure('Kod 6 ta raqamdan iborat'));
    return _repository.verifyCode(params.phone, params.code);
  }
}
