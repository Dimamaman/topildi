import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/firebase_failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._source, this._network);

  final NotificationRemoteDataSource _source;
  final NetworkInfo _network;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      return right(await run());
    } catch (e) {
      return left(failureOf(e));
    }
  }

  @override
  FutureEither<List<AppNotification>> getAll() => _guard(_source.fetchAll);

  @override
  FutureEither<void> markAllRead() => _guard(_source.markAll);

  @override
  FutureEither<void> markRead(String id) => _guard(() => _source.mark(id));

  /// A failing stream (offline, rules) just stops the badge: it keeps the last count.
  @override
  Stream<int> watchUnread() => _source.watchUnread().handleError((Object _) {});
}
