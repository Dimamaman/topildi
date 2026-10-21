import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/entities/app_notification.dart';

@lazySingleton
class NotificationMockDataSource {
  NotificationMockDataSource() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);
    _items = [
      AppNotification(
        id: 'n1',
        kind: NotificationKind.newClaim,
        text: '“Qora charm hamyon” eʼloningizga yangi soʻrov keldi. Javobni tekshiring.',
        createdAt: ago(const Duration(minutes: 5)),
        target: const OpenClaims('l1'),
      ),
      AppNotification(
        id: 'n2',
        kind: NotificationKind.message,
        text: 'Sardor R. sizga xabar yozdi',
        createdAt: ago(const Duration(minutes: 12)),
        target: const OpenChat('c_sardor'),
      ),
      AppNotification(
        id: 'n3',
        kind: NotificationKind.match,
        text: '“Pasport” eʼloningizga oʻxshash buyum topildi: Olmazor',
        createdAt: ago(const Duration(hours: 1)),
        target: const OpenListing('l5'),
      ),
      AppNotification(
        id: 'n4',
        kind: NotificationKind.claimAccepted,
        text: 'Soʻrovingiz qabul qilindi! Endi topuvchi bilan yozishishingiz mumkin.',
        createdAt: ago(const Duration(days: 1, hours: 2)),
        target: const OpenChat('c_sardor'),
        read: true,
      ),
      AppNotification(
        id: 'n5',
        kind: NotificationKind.returned,
        text: 'Kalitlar egasiga qaytdi. Rahmat, sizdek insonlar koʻpaysin!',
        createdAt: ago(const Duration(days: 2)),
        target: const OpenSuccess('c_nilufar'),
        read: true,
      ),
      AppNotification(
        id: 'n6',
        kind: NotificationKind.expiring,
        text: '“Ryukzak” eʼloningiz 3 kundan soʻng arxivlanadi. Yangilaysizmi?',
        createdAt: ago(const Duration(days: 4)),
        target: const OpenProfile(),
        read: true,
      ),
      AppNotification(
        id: 'n7',
        kind: NotificationKind.message,
        text: 'Ozoda N. sizga xabar yozdi',
        createdAt: ago(const Duration(minutes: 35)),
        target: const OpenChat('c_ozoda'),
      ),
      AppNotification(
        id: 'n8',
        kind: NotificationKind.newClaim,
        text: '“Pasport, qizil muqovali” eʼloningizga 2 ta yangi soʻrov keldi.',
        createdAt: ago(const Duration(hours: 6)),
        target: const OpenClaims('l_mine3'),
      ),
      AppNotification(
        id: 'n9',
        kind: NotificationKind.newClaim,
        text: '“Telefon, oltin rangli” eʼloningizga yangi soʻrov keldi.',
        createdAt: ago(const Duration(hours: 3)),
        target: const OpenClaims('l_mine2'),
        read: true,
      ),
      AppNotification(
        id: 'n10',
        kind: NotificationKind.match,
        text: '“Quloqchin” eʼloningizga oʻxshash buyum topildi: Chilonzor',
        createdAt: ago(const Duration(days: 1, hours: 5)),
        target: const OpenListing('l6'),
        read: true,
      ),
      AppNotification(
        id: 'n11',
        kind: NotificationKind.claimAccepted,
        text: 'Jasur M. soʻrovingizni qabul qildi. Chatda kelishib oling.',
        createdAt: ago(const Duration(days: 2)),
        target: const OpenChat('c_jasur'),
        read: true,
      ),
      AppNotification(
        id: 'n12',
        kind: NotificationKind.returned,
        text: 'Hamyon egasiga qaytdi. Rahmat, siz tufayli bir kishi xursand!',
        createdAt: ago(const Duration(days: 14)),
        target: const OpenSuccess('c_timur'),
        read: true,
      ),
      AppNotification(
        id: 'n13',
        kind: NotificationKind.expiring,
        text: '“Haydovchilik guvohnomasi” eʼloningiz 5 kundan soʻng arxivlanadi. Yangilaysizmi?',
        createdAt: ago(const Duration(days: 6)),
        target: const OpenProfile(),
        read: true,
      ),
    ];
  }

  late List<AppNotification> _items;
  final _unread = StreamController<int>.broadcast();

  int get unread => _items.where((n) => !n.read).length;

  Stream<int> watchUnread() async* {
    yield unread;
    yield* _unread.stream;
  }

  Future<List<AppNotification>> fetchAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable([..._items]..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  void markAll() {
    _items = [for (final n in _items) n.markRead()];
    _unread.add(unread);
  }

  void mark(String id) {
    _items = [for (final n in _items) n.id == id ? n.markRead() : n];
    _unread.add(unread);
  }
}
