import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/di/firebase_module.dart';
import '../../domain/entities/report.dart';
import 'report_remote_datasource.dart';

/// In-memory shikoyatlar for widget tests: nothing leaves the device, and a
/// second report on the same target is refused while the first is open,
/// exactly as the rules do.
@test
@LazySingleton(as: ReportRemoteDataSource)
class ReportMockDataSource implements ReportRemoteDataSource {
  final _sent = <String, SubmitReportParams>{};

  /// What the tests assert on.
  Map<String, SubmitReportParams> get sent => Map.unmodifiable(_sent);

  String _id(ReportTargetType type, String targetId, String reporterId) =>
      FirePaths.reportId(type.name, targetId, reporterId);

  /// Ids a moderator has closed, so the next report on them goes through.
  final _closed = <String>{};

  /// Ticks whenever a report is written or closed, for [watchMyReport].
  final _changes = StreamController<void>.broadcast();

  /// Stands in for the moderator pressing "Yopish" in Telegram.
  void close(ReportTargetType type, String targetId, String reporterId) {
    _closed.add(_id(type, targetId, reporterId));
    _changes.add(null);
  }

  /// When each one was sent, as the server timestamp would be.
  final _at = <String, DateTime>{};

  @override
  Future<void> add(SubmitReportParams params, String reporterId) async {
    final id = _id(params.target.type, params.target.id, reporterId);
    _sent[id] = params;
    _at[id] = DateTime.now();
    _closed.remove(id);
    _changes.add(null);
  }

  @override
  Future<MyReport?> myReport(ReportTargetType type, String targetId, String reporterId) async {
    final id = _id(type, targetId, reporterId);
    if (!_sent.containsKey(id)) return null;
    return MyReport(
      status: _closed.contains(id) ? ReportStatus.resolved : ReportStatus.open,
      createdAt: _at[id],
    );
  }

  @override
  Stream<MyReport?> watchMyReport(ReportTargetType type, String targetId, String reporterId) async* {
    yield await myReport(type, targetId, reporterId);
    yield* _changes.stream.asyncMap((_) => myReport(type, targetId, reporterId));
  }
}
