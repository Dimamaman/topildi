import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/entities/app_notification.dart';
import 'notification_remote_datasource.dart';

@test
@LazySingleton(as: NotificationRemoteDataSource)
class NotificationMockDataSource implements NotificationRemoteDataSource {
  NotificationMockDataSource() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);
    _items = [
      AppNotification(
        id: 'n1',
        kind: NotificationKind.newClaim,
        listingTitle: 'Qora charm hamyon',
        createdAt: ago(const Duration(minutes: 5)),
        target: const OpenClaims('l1'),
      ),
      AppNotification(
        id: 'n2',
        kind: NotificationKind.claimAccepted,
        listingTitle: 'Kalitlar toʻplami',
        actorName: 'Sardor R.',
        createdAt: ago(const Duration(minutes: 12)),
        target: const OpenChat('c_sardor'),
      ),
      AppNotification(
        id: 'n3',
        kind: NotificationKind.claimRejected,
        listingTitle: 'Pasport',
        attemptsLeft: 2,
        createdAt: ago(const Duration(hours: 1)),
        target: const OpenListing('l5'),
      ),
      AppNotification(
        id: 'n4',
        kind: NotificationKind.newClaim,
        listingTitle: 'Pasport, qizil muqovali',
        createdAt: ago(const Duration(hours: 6)),
        target: const OpenClaims('l_mine3'),
      ),
      AppNotification(
        id: 'n5',
        kind: NotificationKind.claimAccepted,
        listingTitle: 'Telefon, oltin rangli',
        actorName: 'Jasur M.',
        createdAt: ago(const Duration(days: 1, hours: 2)),
        target: const OpenChat('c_jasur'),
        read: true,
      ),
      AppNotification(
        id: 'n6',
        kind: NotificationKind.returned,
        listingTitle: 'Kalitlar',
        actorName: 'Nilufar A.',
        createdAt: ago(const Duration(days: 2)),
        target: const OpenSuccess('c_nilufar'),
        read: true,
      ),
      AppNotification(
        id: 'n7',
        kind: NotificationKind.claimRejected,
        listingTitle: 'Quloqchin',
        createdAt: ago(const Duration(days: 4)),
        target: const OpenListing('l6'),
        read: true,
      ),
      AppNotification(
        id: 'n8',
        kind: NotificationKind.returned,
        listingTitle: 'Hamyon',
        actorName: 'Timur S.',
        createdAt: ago(const Duration(days: 14)),
        target: const OpenSuccess('c_timur'),
        read: true,
      ),
    ];
  }

  late List<AppNotification> _items;
  final _unread = StreamController<int>.broadcast();

  int get unread => _items.where((n) => !n.read).length;

  @override
  Stream<int> watchUnread() async* {
    yield unread;
    yield* _unread.stream;
  }

  @override
  Future<List<AppNotification>> fetchAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable([..._items]..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  @override
  Future<void> markAll() async {
    _items = [for (final n in _items) n.markRead()];
    _unread.add(unread);
  }

  @override
  Future<void> mark(String id) async {
    _items = [for (final n in _items) n.id == id ? n.markRead() : n];
    _unread.add(unread);
  }
}
