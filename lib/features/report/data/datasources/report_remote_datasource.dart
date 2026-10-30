import '../../domain/entities/report.dart';

/// Where shikoyatlar go: Firestore in the app, an in-memory mock in tests.
/// Nothing ever reads a report back except the reporter's own
/// [hasOpenReport] check — moderation happens in Cloud Functions
/// (functions/src/report.ts).
abstract interface class ReportRemoteDataSource {
  Future<void> add(SubmitReportParams params, String reporterId);

  /// Whether [reporterId] has a report on this target the moderator has not
  /// closed yet. Once it is closed they may report the same target again,
  /// which is what stops a resolved case from silencing them forever.
  Future<bool> hasOpenReport(ReportTargetType type, String targetId, String reporterId);
}
