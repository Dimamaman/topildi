import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/firebase_failure.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';

@LazySingleton(as: ReportRepository)
class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._reports, this._network, this._session);

  final ReportRemoteDataSource _reports;
  final NetworkInfo _network;
  final Session _session;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      return right(await run());
    } catch (e) {
      return left(failureOf(e));
    }
  }

  @override
  FutureEither<void> submit(SubmitReportParams params) => _guard(() async {
    final me = _session.userId;
    if (me.isEmpty) throw const ForbiddenFailure();
    // Reporting yourself is refused by the rules too.
    if (params.target.reportedUid == me) throw const ForbiddenFailure();
    if (params.comment.trim().length > maxReportComment) {
      throw ValidationFailure(tr('Izoh juda uzun'));
    }
    if (await _reports.hasOpenReport(params.target.type, params.target.id, me)) {
      throw ValidationFailure(tr('Shikoyatingiz allaqachon yuborilgan'));
    }
    await _reports.add(params, me);
  });

  @override
  FutureEither<bool> alreadyReported(ReportTargetType type, String targetId) => _guard(() async {
    final me = _session.userId;
    return me.isNotEmpty && await _reports.hasOpenReport(type, targetId, me);
  });
}
