import '../../domain/entities/chat.dart';

/// Where chats live: Firestore in the app, an in-memory mock in tests.
/// A chat is opened by [ClaimRemoteDataSource.accept], never here.
abstract interface class ChatRemoteDataSource {
  /// The signed-in user's chats, newest activity first; emits on every change.
  Stream<List<ChatThread>> watchThreads();

  Future<ChatThread?> fetchThread(String id);

  /// Emits the thread on every change; errors with NotFoundFailure if it
  /// does not exist (or is not ours).
  Stream<ChatThread> watchThread(String id);

  /// All messages, oldest first, including the "matched" and safety notes
  /// at the top.
  Stream<List<ChatMessage>> watchMessages(String id);

  Future<ChatMessage> addMessage(String id, String text);

  /// Clears my unread count and records when I last read the chat.
  Future<void> markRead(String id);

  /// Finder confirms the hand-over: closes the chat and the listing, and
  /// counts one more returned item for the finder.
  Future<void> markReturned(String id);

  /// The owner's thank-you, if they wrote one after the item came back.
  Future<String?> ownerNote(String id);

  /// Items the signed-in user has returned so far.
  Future<int> myReturnedCount();

  /// When the item was handed over and the listing's first photo, for the
  /// thank-you screen (either may be missing).
  Future<({DateTime? returnedAt, String? photo})> returnedItem(String id);
}

/// Texts of the system notes in a chat (translated where they are shown).
abstract final class ChatNotes {
  static const matched = 'Javob yashirin belgiga mos keldi. Chat ochildi.';
  static const safety = 'Gavjum joyda uchrashing. Telefon raqam yoki karta maʼlumotini yozmang.';
  static const returned = 'Buyum egasiga qaytarildi';
}
