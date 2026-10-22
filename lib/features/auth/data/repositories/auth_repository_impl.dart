import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/l10n/tr.dart';

/// Mock auth: any 6-digit code except 000000 is accepted.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._session, this._network);

  final Session _session;
  final NetworkInfo _network;

  /// Number awaiting SMS verification; persisted only after it is verified.
  String? _pendingPhone;

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
  FutureEither<void> requestCode(PhoneNumber phone) => _guard(() async {
        await Future<void>.delayed(_latency);
        _pendingPhone = phone.digits;
      });

  @override
  FutureEither<AuthResult> verifyCode(PhoneNumber phone, String code) => _guard(() async {
        await Future<void>.delayed(_latency);
        if (code == '000000') throw ValidationFailure(tr('Kod notoʻgʻri. Qayta kiriting'));
        await _session.signIn(phone: _pendingPhone ?? phone.digits);
        _pendingPhone = null;
        return const AuthResult(needsProfile: true);
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
