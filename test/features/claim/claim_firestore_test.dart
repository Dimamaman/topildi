import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/features/claim/data/models/claim_firestore.dart';
import 'package:topildi/features/claim/domain/entities/claim.dart';
import 'package:topildi/features/listing/domain/entities/listing.dart';

void main() {
  const claimant = PublicUser(id: 'u2', displayName: 'Malika K.', returnedCount: 1);

  Map<String, Object?> map({String? proofUrl}) => claimToFirestore(
        listingId: 'l1',
        listingAuthorId: 'u1',
        claimant: claimant,
        answer: 'Ichida koʻk karta bor',
        attempt: 2,
        proofUrl: proofUrl,
      );

  test('id is listing, claimant and attempt', () {
    expect(claimDocId('l1', 'u2', 3), 'l1_u2_3');
  });

  test('new claim is pending, has no phone, omits a missing proof', () {
    final m = map();
    expect(m['status'], 'pending');
    expect(m['attempt'], 2);
    expect(m.containsKey('proofUrl'), isFalse);
    expect(m.keys.any((k) => k.toLowerCase().contains('phone')), isFalse);
    expect(map(proofUrl: 'https://x/p.jpg')['proofUrl'], 'https://x/p.jpg');
  });

  test('round trip', () {
    final back = claimFromFirestore('l1_u2_2', {...map(proofUrl: 'https://x/p.jpg'), 'createdAt': Timestamp.now()});
    expect(back.id, 'l1_u2_2');
    expect(back.listingId, 'l1');
    expect(back.claimant, claimant);
    expect(back.answer, 'Ichida koʻk karta bor');
    expect(back.hasProofPhoto, isTrue);
    expect(back.proofPath, 'https://x/p.jpg');
    expect(back.status, ClaimStatus.pending);
  });

  test('unknown status falls back to pending', () {
    expect(claimFromFirestore('x', {'status': '??'}).status, ClaimStatus.pending);
  });
}
