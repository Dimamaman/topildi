import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/telegram_login.dart';
import '../../domain/repositories/auth_repository.dart';

/// Mock auth for widget tests: a Telegram sign-in is confirmed on the
/// second claim, as if the number was shared while the app waited, and
/// arrives with the profile already named (as the server does).
@test
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._session, this._network);

  final Session _session;
  final NetworkInfo _network;

  int _claims = 0;

  static const _latency = Duration(milliseconds: 600);

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      return right(await run());
    } on Failure catch (f) {
      return left(f);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<TelegramLogin> startTelegram() => _guard(() async {
        await Future<void>.delayed(_latency);
        _claims = 0;
        return TelegramLogin(sid: 'mock', secret: 'mock', url: Uri.parse('https://t.me/topildi_bot?start=mock'));
      });

  @override
  FutureEither<AuthResult?> claimTelegram(TelegramLogin login) => _guard(() async {
        await Future<void>.delayed(_latency);
        if (++_claims < 2) return null;
        await _session.signIn(phone: '901234567');
        // The server names the profile after the Telegram account.
        await _session.setName('Malika', '');
        return const AuthResult(needsProfile: false);
      });

  @override
  FutureEither<AuthResult> signInWithGoogle() => _guard(() async {
        await Future<void>.delayed(_latency);
        await _session.signIn();
        return const AuthResult(needsProfile: true);
      });

  @override
  FutureEither<void> saveProfile(ProfileInput input) => _guard(() async {
        await Future<void>.delayed(_latency);
        await _session.setName(input.firstName.trim(), input.lastName.trim());
        await _session.setAvatar(input.photoPath);
        await _session.setAvatarStyle(tone: input.tone, emoji: input.photoPath == null ? input.emoji : null);
      });
}
