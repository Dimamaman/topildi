import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

typedef FutureEither<T> = Future<Either<Failure, T>>;

/// A live value: a new [Either] on every change.
typedef StreamEither<T> = Stream<Either<Failure, T>>;

abstract interface class UseCase<T, P> {
  FutureEither<T> call(P params);
}

class NoParams {
  const NoParams();
}
