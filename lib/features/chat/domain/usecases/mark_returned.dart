import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

@injectable
class MarkReturned implements UseCase<ReturnSummary, String> {
  const MarkReturned(this._repository);

  final ChatRepository _repository;

  @override
  FutureEither<ReturnSummary> call(String params) => _repository.markReturned(params);
}
