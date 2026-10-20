import '../../../../core/usecase/usecase.dart';
import '../entities/phone_number.dart';

abstract interface class AuthRepository {
  FutureEither<void> requestCode(PhoneNumber phone);

  FutureEither<AuthResult> verifyCode(PhoneNumber phone, String code);

  FutureEither<AuthResult> signInWithGoogle();

  FutureEither<void> saveProfile(ProfileInput input);
}
