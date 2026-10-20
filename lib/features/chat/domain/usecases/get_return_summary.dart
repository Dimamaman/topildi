import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

@injectable
class GetReturnSummary implements UseCase<ReturnSummary, String> {
  const GetReturnSummary(this._repository);

  final ChatRepository _repository;

  @override
  FutureEither<ReturnSummary> call(String params) => _repository.getReturnSummary(params);
}
