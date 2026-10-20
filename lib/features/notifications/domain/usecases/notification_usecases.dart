import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

@injectable
class GetNotifications implements UseCase<List<AppNotification>, NoParams> {
  const GetNotifications(this._repository);
  final NotificationRepository _repository;
  @override
  FutureEither<List<AppNotification>> call(NoParams params) => _repository.getAll();
}

@injectable
class MarkAllNotificationsRead implements UseCase<void, NoParams> {
  const MarkAllNotificationsRead(this._repository);
  final NotificationRepository _repository;
  @override
  FutureEither<void> call(NoParams params) => _repository.markAllRead();
}

@injectable
class MarkNotificationRead implements UseCase<void, String> {
  const MarkNotificationRead(this._repository);
  final NotificationRepository _repository;
  @override
  FutureEither<void> call(String params) => _repository.markRead(params);
}

@injectable
class WatchUnreadNotifications {
  const WatchUnreadNotifications(this._repository);
  final NotificationRepository _repository;
  Stream<int> call() => _repository.watchUnread();
}
