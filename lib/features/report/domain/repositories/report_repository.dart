import '../../../../core/usecase/usecase.dart';
import '../entities/report.dart';

abstract interface class ReportRepository {
  /// Stores the shikoyat; a Cloud Function passes it to the moderator.
  /// Fails with [ValidationFailure] while this user's earlier report on the
  /// same target is still open, and with [ForbiddenFailure] on their own
  /// listing.
  FutureEither<void> submit(SubmitReportParams params);

  /// True while the signed-in user's report on this target is still open
  /// (the sheet then shows "Allaqachon yuborilgan" instead of the form).
  /// A closed one lets them report the same target again.
  FutureEither<bool> alreadyReported(ReportTargetType type, String targetId);
}
