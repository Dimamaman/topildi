import '../../../../core/usecase/usecase.dart';
import '../entities/report.dart';

abstract interface class ReportRepository {
  /// Stores the shikoyat; a Cloud Function passes it to the moderator.
  /// Fails with [ValidationFailure] when this user already reported the
  /// same target, and with [ForbiddenFailure] on their own listing.
  FutureEither<void> submit(SubmitReportParams params);

  /// True when the signed-in user has already reported this target (the
  /// sheet then shows "Allaqachon yuborilgan" instead of the form).
  FutureEither<bool> alreadyReported(ReportTargetType type, String targetId);
}
