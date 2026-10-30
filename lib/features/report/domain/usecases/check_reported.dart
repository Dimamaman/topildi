import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/report.dart';
import '../repositories/report_repository.dart';

/// Asked before the sheet opens: this person's own report on the target,
/// with where it stands.
@injectable
class CheckReported implements UseCase<MyReport?, ({ReportTargetType type, String targetId})> {
  const CheckReported(this._repository);

  final ReportRepository _repository;

  @override
  FutureEither<MyReport?> call(({ReportTargetType type, String targetId}) params) =>
      _repository.myReport(params.type, params.targetId);
}
