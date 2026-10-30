import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/report.dart';
import '../repositories/report_repository.dart';

@injectable
class SubmitReport implements UseCase<void, SubmitReportParams> {
  const SubmitReport(this._repository);

  final ReportRepository _repository;

  @override
  FutureEither<void> call(SubmitReportParams params) => _repository.submit(params);
}
