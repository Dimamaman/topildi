import '../../../../core/usecase/usecase.dart';
import '../entities/auth_result.dart';
import '../entities/telegram_login.dart';

abstract interface class AuthRepository {
  /// Starts a sign-in through the Telegram bot.
  FutureEither<TelegramLogin> startTelegram();

  /// Signs in once the number is shared in Telegram; null while still waiting.
  FutureEither<AuthResult?> claimTelegram(TelegramLogin login);

  FutureEither<AuthResult> signInWithGoogle();

  FutureEither<void> saveProfile(ProfileInput input);
}
