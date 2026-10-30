import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/blocked_user.dart';
import '../repositories/block_repository.dart';

@injectable
class WatchBlocked {
  const WatchBlocked(this._repository);

  final BlockRepository _repository;

  StreamEither<List<BlockedUser>> call() => _repository.watchBlocked();
}
