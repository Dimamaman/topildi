import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';

/// `topildi_users/{uid}/notifications/{id}`, written by Cloud Functions
/// (`functions/src/notify.ts`); the owner may only set `read`. Unknown kinds
/// (from a newer server) read as null and are skipped.
AppNotification? notificationFromFirestore(String id, Map<String, dynamic> d) {
  final kind = NotificationKind.values.where((k) => k.name == d['kind']).firstOrNull;
  if (kind == null) return null;
  final listingId = d['listingId'] as String? ?? '';
  final chatId = d['chatId'] as String? ?? '';
  return AppNotification(
    id: id,
    kind: kind,
    listingTitle: d['listingTitle'] as String? ?? '',
    actorName: d['actorName'] as String? ?? '',
    attemptsLeft: (d['attemptsLeft'] as num?)?.toInt() ?? 0,
    createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    read: d['read'] as bool? ?? false,
    target: switch (kind) {
      NotificationKind.newClaim => OpenClaims(listingId),
      NotificationKind.claimAccepted => OpenChat(chatId),
      NotificationKind.claimRejected => OpenListing(listingId),
      NotificationKind.returned => OpenSuccess(chatId),
    },
  );
}
