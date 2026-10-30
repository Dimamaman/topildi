import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/report.dart';
import '../repositories/report_repository.dart';

/// Asked before the sheet opens: has this person reported this target before?
@injectable
class CheckReported implements UseCase<bool, ({ReportTargetType type, String targetId})> {
  const CheckReported(this._repository);

  final ReportRepository _repository;

  @override
  FutureEither<bool> call(({ReportTargetType type, String targetId}) params) =>
      _repository.alreadyReported(params.type, params.targetId);
}
