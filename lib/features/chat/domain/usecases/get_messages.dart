import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

@injectable
class GetMessages implements UseCase<List<ChatMessage>, String> {
  const GetMessages(this._repository);

  final ChatRepository _repository;

  @override
  FutureEither<List<ChatMessage>> call(String params) => _repository.getMessages(params);
}
