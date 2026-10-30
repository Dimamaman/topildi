import '../../../../core/usecase/usecase.dart';
import '../entities/blocked_user.dart';

abstract interface class BlockRepository {
  /// The signed-in user's blocked list, newest first; a new list on every change.
  StreamEither<List<BlockedUser>> watchBlocked();

  FutureEither<void> block(String uid, String name);

  FutureEither<void> unblock(String uid);

  /// Did the signed-in user block [uid], and did [uid] block them? The chat
  /// asks for both: only the first one can be undone from there.
  FutureEither<({bool byMe, bool ofMe})> blockState(String uid);
}
