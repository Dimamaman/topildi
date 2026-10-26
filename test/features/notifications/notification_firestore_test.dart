import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/features/notifications/data/models/notification_firestore.dart';
import 'package:topildi/features/notifications/domain/entities/app_notification.dart';

void main() {
  final at = DateTime(2026, 10, 26, 9);

  test('each kind opens its screen', () {
    AppNotification? of(String kind) => notificationFromFirestore('n1', {
      'kind': kind,
      'listingId': 'l1',
      'listingTitle': 'Qora hamyon',
      'chatId': 'l1_u2_1',
      'actorName': 'Dilshod A.',
      'attemptsLeft': 2,
      'read': false,
      'createdAt': Timestamp.fromDate(at),
    });

    expect(of('newClaim')!.target, const OpenClaims('l1'));
    expect(of('claimAccepted')!.target, const OpenChat('l1_u2_1'));
    expect(of('claimRejected')!.target, const OpenListing('l1'));
    expect(of('returned')!.target, const OpenSuccess('l1_u2_1'));

    final n = of('claimRejected')!;
    expect(n.listingTitle, 'Qora hamyon');
    expect(n.actorName, 'Dilshod A.');
    expect(n.attemptsLeft, 2);
    expect(n.createdAt, at);
    expect(n.read, isFalse);
  });

  test('unknown kinds from a newer server are skipped', () {
    expect(notificationFromFirestore('n1', {'kind': 'somethingNew'}), isNull);
  });

  test('missing fields fall back to defaults', () {
    final n = notificationFromFirestore('n1', {'kind': 'newClaim'})!;
    expect(n.listingTitle, '');
    expect(n.attemptsLeft, 0);
    expect(n.read, isFalse);
  });
}
