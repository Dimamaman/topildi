import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_mock_datasource.dart';

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(this._source, this._network);

  final NotificationMockDataSource _source;
  final NetworkInfo _network;

  @override
  FutureEither<List<AppNotification>> getAll() async {
    if (!await _network.isConnected) return left(const NetworkFailure());
    try {
      return right(await _source.fetchAll());
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  FutureEither<void> markAllRead() async => right(_source.markAll());

  @override
  FutureEither<void> markRead(String id) async => right(_source.mark(id));

  @override
  Stream<int> watchUnread() => _source.watchUnread();
}
