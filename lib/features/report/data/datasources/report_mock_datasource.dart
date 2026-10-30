import 'package:injectable/injectable.dart';

import '../../../../core/di/firebase_module.dart';
import '../../domain/entities/report.dart';
import 'report_remote_datasource.dart';

/// In-memory shikoyatlar for widget tests: nothing leaves the device, and a
/// second report on the same target is refused exactly as the rules do.
@test
@LazySingleton(as: ReportRemoteDataSource)
class ReportMockDataSource implements ReportRemoteDataSource {
  final _sent = <String, SubmitReportParams>{};

  /// What the tests assert on.
  Map<String, SubmitReportParams> get sent => Map.unmodifiable(_sent);

  String _id(ReportTargetType type, String targetId, String reporterId) =>
      FirePaths.reportId(type.name, targetId, reporterId);

  @override
  Future<void> add(SubmitReportParams params, String reporterId) async {
    _sent[_id(params.target.type, params.target.id, reporterId)] = params;
  }

  @override
  Future<bool> exists(ReportTargetType type, String targetId, String reporterId) async =>
      _sent.containsKey(_id(type, targetId, reporterId));
}
