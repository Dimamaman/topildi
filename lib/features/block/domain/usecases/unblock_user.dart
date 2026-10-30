import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../repositories/block_repository.dart';

@injectable
class UnblockUser implements UseCase<void, String> {
  const UnblockUser(this._repository);

  final BlockRepository _repository;

  @override
  FutureEither<void> call(String params) => _repository.unblock(params);
}
