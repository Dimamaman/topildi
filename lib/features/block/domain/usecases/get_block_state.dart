import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../repositories/block_repository.dart';

/// Both directions for one person, for the chat's bottom bar.
@injectable
class GetBlockState implements UseCase<({bool byMe, bool ofMe}), String> {
  const GetBlockState(this._repository);

  final BlockRepository _repository;

  @override
  FutureEither<({bool byMe, bool ofMe})> call(String params) => _repository.blockState(params);
}
