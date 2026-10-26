import '../../domain/entities/app_notification.dart';

/// The signed-in user's notifications: Firestore in the app (written by the
/// Cloud Functions that also send the push), an in-memory mock in tests.
abstract interface class NotificationRemoteDataSource {
  /// Newest first.
  Future<List<AppNotification>> fetchAll();

  /// Unread count, re-emitted on every change.
  Stream<int> watchUnread();

  Future<void> markAll();

  Future<void> mark(String id);
}
