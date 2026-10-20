import '../../../../core/usecase/usecase.dart';
import '../entities/profile_summary.dart';

abstract interface class ProfileRepository {
  FutureEither<ProfileSummary> getMine();

  FutureEither<void> setNotifications(bool on);

  FutureEither<void> signOut();
}
