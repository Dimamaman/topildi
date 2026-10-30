import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../repositories/block_repository.dart';

@injectable
class BlockUser implements UseCase<void, ({String uid, String name})> {
  const BlockUser(this._repository);

  final BlockRepository _repository;

  @override
  FutureEither<void> call(({String uid, String name}) params) => _repository.block(params.uid, params.name);
}
