import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';

abstract interface class ChatRepository {
  FutureEither<List<ChatThread>> getChats();

  /// Emits when the chat list may have changed.
  Stream<void> get changes;

  FutureEither<ChatThread> getThread(String chatId);

  FutureEither<List<ChatMessage>> getMessages(String chatId);

  FutureEither<ChatMessage> send(String chatId, String text);

  /// Finder confirms the hand-over; closes the listing as returned.
  FutureEither<ReturnSummary> markReturned(String chatId);

  FutureEither<ReturnSummary> getReturnSummary(String chatId);
}
