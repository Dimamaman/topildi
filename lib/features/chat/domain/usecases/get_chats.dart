import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

@injectable
class GetChats implements UseCase<List<ChatThread>, NoParams> {
  const GetChats(this._repository);

  final ChatRepository _repository;

  @override
  FutureEither<List<ChatThread>> call(NoParams params) => _repository.getChats();
}
