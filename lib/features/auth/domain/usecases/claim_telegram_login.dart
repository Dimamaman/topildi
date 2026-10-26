import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/auth_result.dart';
import '../entities/telegram_login.dart';
import '../repositories/auth_repository.dart';

/// Right(null) while the number has not been shared in Telegram yet.
@injectable
class ClaimTelegramLogin implements UseCase<AuthResult?, TelegramLogin> {
  const ClaimTelegramLogin(this._repository);

  final AuthRepository _repository;

  @override
  FutureEither<AuthResult?> call(TelegramLogin params) => _repository.claimTelegram(params);
}
