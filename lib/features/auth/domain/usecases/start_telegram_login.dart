import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/telegram_login.dart';
import '../repositories/auth_repository.dart';

@injectable
class StartTelegramLogin implements UseCase<TelegramLogin, NoParams> {
  const StartTelegramLogin(this._repository);

  final AuthRepository _repository;

  @override
  FutureEither<TelegramLogin> call(NoParams params) => _repository.startTelegram();
}
