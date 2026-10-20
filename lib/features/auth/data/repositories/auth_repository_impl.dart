import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/repositories/auth_repository.dart';

/// Mock auth: any 6-digit code except 000000 is accepted.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._session, this._network);

  final Session _session;
  final NetworkInfo _network;

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
        _session.phone = phone.digits;
      });

  @override
  FutureEither<AuthResult> verifyCode(PhoneNumber phone, String code) => _guard(() async {
        await Future<void>.delayed(_latency);
        if (code == '000000') throw const ValidationFailure('Kod notoʻgʻri. Qayta tekshiring');
        _session.signedIn = true;
        return const AuthResult(needsProfile: true);
      });

  @override
  FutureEither<AuthResult> signInWithGoogle() => _guard(() async {
        await Future<void>.delayed(_latency);
        _session.signedIn = true;
        return const AuthResult(needsProfile: true);
      });

  @override
  FutureEither<void> saveProfile(ProfileInput input) => _guard(() async {
        await Future<void>.delayed(_latency);
        _session
          ..firstName = input.firstName.trim()
          ..lastName = input.lastName.trim();
      });
}
