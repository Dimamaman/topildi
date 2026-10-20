import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../listing/data/datasources/listing_mock_datasource.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_mock_datasource.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._chats, this._listings, this._network, this._session);

  final ChatMockDataSource _chats;
  final ListingMockDataSource _listings;
  final NetworkInfo _network;
  final Session _session;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      return right(await run());
    } on Failure catch (f) {
      return left(f);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  Future<ChatThread> _thread(String id) async => await _chats.fetchThread(id) ?? (throw const NotFoundFailure());

  @override
  FutureEither<List<ChatThread>> getChats() => _guard(_chats.fetchThreads);

  @override
  Stream<void> get changes => _chats.changes;

  @override
  FutureEither<ChatThread> getThread(String chatId) => _guard(() => _thread(chatId));

  @override
  FutureEither<List<ChatMessage>> getMessages(String chatId) => _guard(() async {
        await _thread(chatId);
        return _chats.fetchMessages(chatId);
      });

  @override
  FutureEither<ChatMessage> send(String chatId, String text) => _guard(() => _chats.addMessage(chatId, text));

  @override
  FutureEither<ReturnSummary> markReturned(String chatId) => _guard(() async {
        final t = await _thread(chatId);
        if (!t.iAmFinder) throw const ForbiddenFailure();
        await _chats.markReturned(chatId);
        final listing = await _listings.fetchById(t.listingId);
        if (listing != null) await _listings.update(listing.copyWith(status: ListingStatus.returned));
        return _summary(await _thread(chatId));
      });

  @override
  FutureEither<ReturnSummary> getReturnSummary(String chatId) => _guard(() async => _summary(await _thread(chatId)));

  ReturnSummary _summary(ChatThread t) => ReturnSummary(
        listingTitle: t.listingTitle,
        finderName: t.iAmFinder ? _session.displayName : t.other.displayName,
        owner: t.iAmFinder ? t.other : PublicUser(id: _session.userId, displayName: _session.displayName),
        ownerNote: _chats.ownerNote(t.id),
        returnedCount: _chats.myReturnedCount,
        iAmFinder: t.iAmFinder,
      );
}
