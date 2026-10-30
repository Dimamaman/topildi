import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/entities/blocked_user.dart';
import 'block_remote_datasource.dart';

/// In-memory blocks for widget tests. Starts empty: every test that needs a
/// blocked person blocks them through the usual flow.
@test
@LazySingleton(as: BlockRemoteDataSource)
class BlockMockDataSource implements BlockRemoteDataSource {
  final _byOwner = <String, Map<String, BlockedUser>>{};
  final _changes = StreamController<void>.broadcast();

  Map<String, BlockedUser> _list(String ownerId) => _byOwner.putIfAbsent(ownerId, () => {});

  List<BlockedUser> _sorted(String ownerId) =>
      _list(ownerId).values.toList()..sort((a, b) => b.blockedAt.compareTo(a.blockedAt));

  @override
  Stream<List<BlockedUser>> watch(String ownerId) async* {
    yield _sorted(ownerId);
    yield* _changes.stream.map((_) => _sorted(ownerId));
  }

  @override
  Stream<void> changes(String ownerId) => _changes.stream;

  @override
  Future<Set<String>> idsOf(String ownerId) async => _list(ownerId).keys.toSet();

  @override
  Future<void> add(String ownerId, String otherUid, String name) async {
    _list(ownerId)[otherUid] = BlockedUser(id: otherUid, name: name, blockedAt: DateTime.now());
    _changes.add(null);
  }

  @override
  Future<void> remove(String ownerId, String otherUid) async {
    _list(ownerId).remove(otherUid);
    _changes.add(null);
  }

  @override
  Future<bool> blocks(String otherUid, String me) async => _list(otherUid).containsKey(me);
}
