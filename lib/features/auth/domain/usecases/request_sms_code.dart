import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/phone_number.dart';
import '../repositories/auth_repository.dart';

@injectable
class RequestSmsCode implements UseCase<void, PhoneNumber> {
  const RequestSmsCode(this._repository);

  final AuthRepository _repository;

  @override
  FutureEither<void> call(PhoneNumber params) => _repository.requestCode(params);
}
