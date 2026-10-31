import '../../../../core/usecase/usecase.dart';
import '../entities/profile_summary.dart';

abstract interface class ProfileRepository {
  FutureEither<ProfileSummary> getMine();

  FutureEither<void> setNotifications(bool on);

  /// Whether the user's name may be shown on the items they returned.
  FutureEither<bool> getShowNameOnReturns();

  /// Turning it off takes the name off every story at once: the server
  /// clears `finderDisplayName` on all of this user's returned listings.
  FutureEither<void> setShowNameOnReturns(bool on);

  FutureEither<void> signOut();

  /// Deletes the account and everything in it, then signs out.
  FutureEither<void> deleteAccount();
}
