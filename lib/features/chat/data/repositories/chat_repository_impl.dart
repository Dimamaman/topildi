import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/firebase_failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._chats, this._network, this._session);

  final ChatRemoteDataSource _chats;
  final NetworkInfo _network;
  final Session _session;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      return right(await run());
    } catch (e) {
      return left(failureOf(e));
    }
  }

  /// Offline is reported once up front; after that the stream's own errors
  /// become failures and the stream ends.
  StreamEither<T> _live<T>(Stream<T> Function() open) async* {
    if (!await _network.isConnected) {
      yield left(const NetworkFailure());
      return;
    }
    try {
      await for (final v in open()) {
        yield right(v);
      }
    } catch (e) {
      yield left(failureOf(e));
    }
  }

  Future<ChatThread> _thread(String id) async => await _chats.fetchThread(id) ?? (throw const NotFoundFailure());

  @override
  StreamEither<List<ChatThread>> watchChats() => _live(_chats.watchThreads);

  @override
  FutureEither<ChatThread> getThread(String chatId) => _guard(() => _thread(chatId));

  @override
  StreamEither<ChatThread> watchThread(String chatId) => _live(() => _chats.watchThread(chatId));

  @override
  StreamEither<List<ChatMessage>> watchMessages(String chatId) => _live(() => _chats.watchMessages(chatId));

  @override
  FutureEither<ChatMessage> send(String chatId, String text) => _guard(() => _chats.addMessage(chatId, text));

  @override
  FutureEither<void> markRead(String chatId) => _guard(() => _chats.markRead(chatId));

  @override
  FutureEither<ReturnSummary> markReturned(String chatId) => _guard(() async {
        final t = await _thread(chatId);
        if (!t.iAmFinder) throw const ForbiddenFailure();
        await _chats.markReturned(chatId);
        return _summary(await _thread(chatId));
      });

  @override
  FutureEither<ReturnSummary> getReturnSummary(String chatId) => _guard(() async => _summary(await _thread(chatId)));

  Future<ReturnSummary> _summary(ChatThread t) async {
    final item = await _chats.returnedItem(t.id);
    return ReturnSummary(
        listingId: t.listingId,
        listingTitle: t.listingTitle,
        listingCategory: t.listingCategory,
        listingTint: t.listingTint,
        listingPhoto: item.photo,
        returnedAt: item.returnedAt ?? t.lastAt,
        finderName: t.iAmFinder ? _session.displayName : t.other.displayName,
        owner: t.iAmFinder ? t.other : PublicUser(id: _session.userId, displayName: _session.displayName),
        ownerNote: await _chats.ownerNote(t.id),
        returnedCount: await _chats.myReturnedCount(),
        iAmFinder: t.iAmFinder,
      );
  }
}
