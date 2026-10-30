import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/di/firebase_module.dart';
import '../../domain/entities/report.dart';
import 'report_remote_datasource.dart';

/// `topildi_reports/{targetType}_{targetId}_{reporterUid}`: the id is what
/// keeps one person from reporting the same thing twice while the moderator
/// is looking at it. [add] writes the whole document, so it also re-opens a
/// closed one; the rules allow that and the reporter's own `get`.
@prod
@LazySingleton(as: ReportRemoteDataSource)
class FirestoreReportDataSource implements ReportRemoteDataSource {
  const FirestoreReportDataSource(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(ReportTargetType type, String targetId, String reporterId) =>
      _db.collection(FirePaths.reports).doc(FirePaths.reportId(type.name, targetId, reporterId));

  @override
  Future<void> add(SubmitReportParams params, String reporterId) async {
    final comment = params.comment.trim();
    await _doc(params.target.type, params.target.id, reporterId).set({
      'targetType': params.target.type.name,
      'targetId': params.target.id,
      'reportedUid': params.target.reportedUid,
      'reporterId': reporterId,
      'reason': params.reason.name,
      if (comment.isNotEmpty) 'comment': comment,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<MyReport?> myReport(ReportTargetType type, String targetId, String reporterId) async =>
      _toEntity(await _doc(type, targetId, reporterId).get());

  @override
  Stream<MyReport?> watchMyReport(ReportTargetType type, String targetId, String reporterId) =>
      _doc(type, targetId, reporterId).snapshots().map(_toEntity);

  MyReport? _toEntity(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final at = data['createdAt'];
    return MyReport(
      // An unknown status is treated as still open: the sheet then says it
      // is with a moderator rather than inventing an outcome.
      status: ReportStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ReportStatus.open,
      ),
      createdAt: at is Timestamp ? at.toDate() : null,
    );
  }
}
