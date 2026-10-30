import '../../domain/entities/report.dart';

/// Where shikoyatlar go: Firestore in the app, an in-memory mock in tests.
/// Nothing ever reads a report back except the reporter's own [exists]
/// check — moderation happens in Cloud Functions (functions/src/report.ts).
abstract interface class ReportRemoteDataSource {
  Future<void> add(SubmitReportParams params, String reporterId);

  /// Whether [reporterId] already reported this target.
  Future<bool> exists(ReportTargetType type, String targetId, String reporterId);
}
