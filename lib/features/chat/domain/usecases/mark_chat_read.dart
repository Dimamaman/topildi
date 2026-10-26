import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../repositories/chat_repository.dart';

@injectable
class MarkChatRead implements UseCase<void, String> {
  const MarkChatRead(this._repository);

  final ChatRepository _repository;

  @override
  FutureEither<void> call(String params) => _repository.markRead(params);
}
