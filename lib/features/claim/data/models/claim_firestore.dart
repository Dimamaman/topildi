import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/claim.dart';

/// Id of a claimant's [attempt]-th claim (1..3) on a listing. Being
/// predictable lets the rules cap attempts and allow one pending at a time.
String claimDocId(String listingId, String claimantId, int attempt) => '${listingId}_${claimantId}_$attempt';

/// Firestore shape of `topildi_claims/{id}`. Readable only by the claimant
/// and the listing's author; no phone number.
Map<String, Object?> claimToFirestore({
  required String listingId,
  required String listingAuthorId,
  required PublicUser claimant,
  required String answer,
  required int attempt,
  String? proofUrl,
}) => {
  'listingId': listingId,
  'listingAuthorId': listingAuthorId,
  'claimantId': claimant.id,
  'claimantName': claimant.displayName,
  'claimantReturnedCount': claimant.returnedCount,
  'answer': answer,
  'attempt': attempt,
  'proofUrl': ?proofUrl,
  'status': ClaimStatus.pending.name,
  'createdAt': FieldValue.serverTimestamp(),
};

Claim claimFromFirestore(String id, Map<String, dynamic> d) {
  final proof = d['proofUrl'] as String?;
  return Claim(
    id: id,
    listingId: d['listingId'] as String? ?? '',
    claimant: PublicUser(
      id: d['claimantId'] as String? ?? '',
      displayName: d['claimantName'] as String? ?? '',
      returnedCount: (d['claimantReturnedCount'] as num?)?.toInt() ?? 0,
    ),
    answer: d['answer'] as String? ?? '',
    // Pending server timestamp (own write, not yet acknowledged) reads as null.
    createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    hasProofPhoto: proof != null,
    proofPath: proof,
    status: ClaimStatus.values.firstWhere((s) => s.name == d['status'], orElse: () => ClaimStatus.pending),
  );
}
