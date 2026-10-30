import '../../../../core/usecase/usecase.dart';
import '../entities/report.dart';

abstract interface class ReportRepository {
  /// Stores the shikoyat; a Cloud Function passes it to the moderator.
  /// Fails with [ValidationFailure] while this user's earlier report on the
  /// same target is still open, and with [ForbiddenFailure] on their own
  /// listing.
  FutureEither<void> submit(SubmitReportParams params);

  /// The signed-in user's own report on this target, or null. The sheet
  /// shows its progress instead of the form; a closed one also carries the
  /// moderator's outcome, and they may report the target again.
  FutureEither<MyReport?> myReport(ReportTargetType type, String targetId);

  /// The same report as [myReport], live, so SH6 follows the moderator.
  StreamEither<MyReport?> watchMyReport(ReportTargetType type, String targetId);
}
