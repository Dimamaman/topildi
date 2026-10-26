import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

@injectable
class WatchChats {
  const WatchChats(this._repository);

  final ChatRepository _repository;

  StreamEither<List<ChatThread>> call() => _repository.watchChats();
}
