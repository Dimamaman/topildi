import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/firebase_failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/blocked_user.dart';
import '../../domain/repositories/block_repository.dart';
import '../datasources/block_remote_datasource.dart';

@LazySingleton(as: BlockRepository)
class BlockRepositoryImpl implements BlockRepository {
  const BlockRepositoryImpl(this._blocks, this._network, this._session);

  final BlockRemoteDataSource _blocks;
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

  @override
  StreamEither<List<BlockedUser>> watchBlocked() async* {
    final me = _session.userId;
    if (me.isEmpty) {
      yield left(const ForbiddenFailure());
      return;
    }
    if (!await _network.isConnected) {
      yield left(const NetworkFailure());
      return;
    }
    try {
      await for (final list in _blocks.watch(me)) {
        yield right(list);
      }
    } catch (e) {
      yield left(failureOf(e));
    }
  }

  @override
  FutureEither<void> block(String uid, String name) => _guard(() async {
    final me = _session.userId;
    if (me.isEmpty || uid.isEmpty || uid == me) throw const ForbiddenFailure();
    await _blocks.add(me, uid, name.trim());
  });

  @override
  FutureEither<void> unblock(String uid) => _guard(() async {
    final me = _session.userId;
    if (me.isEmpty) throw const ForbiddenFailure();
    await _blocks.remove(me, uid);
  });

  @override
  FutureEither<({bool byMe, bool ofMe})> blockState(String uid) => _guard(() async {
    final me = _session.userId;
    if (me.isEmpty || uid.isEmpty) return (byMe: false, ofMe: false);
    final mine = await _blocks.idsOf(me);
    // Only this one document of theirs is readable; a refusal means no block.
    var theirs = false;
    try {
      theirs = await _blocks.blocks(uid, me);
    } catch (_) {
      theirs = false;
    }
    return (byMe: mine.contains(uid), ofMe: theirs);
  });
}
