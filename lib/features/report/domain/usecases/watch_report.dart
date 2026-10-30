import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/report.dart';
import '../repositories/report_repository.dart';

/// Follows this person's own shikoyat while SH6 is open, so the moderator's
/// decision lands on the steps without the sheet being reopened.
@injectable
class WatchReport {
  const WatchReport(this._repository);

  final ReportRepository _repository;

  StreamEither<MyReport?> call(({ReportTargetType type, String targetId}) params) =>
      _repository.watchMyReport(params.type, params.targetId);
}
