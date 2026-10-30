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

  /// Stands in for the moderator pressing "Yopish" in Telegram.
  void close(ReportTargetType type, String targetId, String reporterId) {
    _closed.add(_id(type, targetId, reporterId));
  }

  @override
  Future<void> add(SubmitReportParams params, String reporterId) async {
    final id = _id(params.target.type, params.target.id, reporterId);
    _sent[id] = params;
    _closed.remove(id);
  }

  @override
  Future<bool> hasOpenReport(ReportTargetType type, String targetId, String reporterId) async {
    final id = _id(type, targetId, reporterId);
    return _sent.containsKey(id) && !_closed.contains(id);
  }
}
