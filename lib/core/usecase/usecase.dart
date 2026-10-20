import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

typedef FutureEither<T> = Future<Either<Failure, T>>;

abstract interface class UseCase<T, P> {
  FutureEither<T> call(P params);
}

class NoParams {
  const NoParams();
}
