import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

/// One chat, live: the thread (read state, returned flag) and its messages.
@injectable
class WatchChat {
  const WatchChat(this._repository);

  final ChatRepository _repository;

  StreamEither<ChatThread> thread(String chatId) => _repository.watchThread(chatId);

  StreamEither<List<ChatMessage>> messages(String chatId) => _repository.watchMessages(chatId);
}
