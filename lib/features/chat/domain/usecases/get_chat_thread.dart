import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

@injectable
class GetChatThread implements UseCase<ChatThread, String> {
  const GetChatThread(this._repository);

  final ChatRepository _repository;

  @override
  FutureEither<ChatThread> call(String params) => _repository.getThread(params);
}
