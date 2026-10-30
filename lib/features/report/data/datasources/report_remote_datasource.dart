import '../../domain/entities/report.dart';

/// Where shikoyatlar go: Firestore in the app, an in-memory mock in tests.
/// Nothing ever reads a report back except the reporter's own
/// [myReport] — moderation happens in Cloud Functions
/// (functions/src/report.ts).
abstract interface class ReportRemoteDataSource {
  Future<void> add(SubmitReportParams params, String reporterId);

  /// [reporterId]'s own report on this target, open or closed, or null when
  /// they have never reported it. Once it is closed they may report the same
  /// target again, which is what stops a resolved case from silencing them.
  Future<MyReport?> myReport(ReportTargetType type, String targetId, String reporterId);

  /// The same report, live: while SH6 is open the moderator's decision
  /// reaches it without the sheet being closed and opened again.
  Stream<MyReport?> watchMyReport(ReportTargetType type, String targetId, String reporterId);
}
