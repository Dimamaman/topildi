import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';

abstract interface class NotificationRepository {
  FutureEither<List<AppNotification>> getAll();

  FutureEither<void> markAllRead();

  FutureEither<void> markRead(String id);

  /// Current unread count, re-emitted on every change.
  Stream<int> watchUnread();
}
