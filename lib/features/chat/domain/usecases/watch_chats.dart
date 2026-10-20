import 'package:injectable/injectable.dart';

import '../repositories/chat_repository.dart';

@injectable
class WatchChats {
  const WatchChats(this._repository);

  final ChatRepository _repository;

  Stream<void> call() => _repository.changes;
}
