import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';
import '../repositories/chat_repository.dart';

typedef SendMessageParams = ({String chatId, String text});

@injectable
class SendMessage implements UseCase<ChatMessage, SendMessageParams> {
  const SendMessage(this._repository);

  final ChatRepository _repository;

  @override
  FutureEither<ChatMessage> call(SendMessageParams params) async {
    final text = params.text.trim();
    if (text.isEmpty) return left(const ValidationFailure());
    return _repository.send(params.chatId, text);
  }
}
