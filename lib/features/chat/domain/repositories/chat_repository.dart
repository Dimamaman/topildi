import '../../../../core/usecase/usecase.dart';
import '../entities/chat.dart';

abstract interface class ChatRepository {
  /// The signed-in user's chats; a new list on every change.
  StreamEither<List<ChatThread>> watchChats();

  FutureEither<ChatThread> getThread(String chatId);

  StreamEither<ChatThread> watchThread(String chatId);

  StreamEither<List<ChatMessage>> watchMessages(String chatId);

  FutureEither<ChatMessage> send(String chatId, String text);

  /// The signed-in user has seen every message in the chat.
  FutureEither<void> markRead(String chatId);

  /// Finder confirms the hand-over; closes the listing as returned.
  FutureEither<ReturnSummary> markReturned(String chatId);

  FutureEither<ReturnSummary> getReturnSummary(String chatId);
}
