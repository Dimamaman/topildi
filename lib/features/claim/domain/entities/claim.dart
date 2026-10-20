import 'package:equatable/equatable.dart';

import '../../../listing/domain/entities/listing.dart';

enum ClaimStatus { pending, accepted, rejected }

class Claim extends Equatable {
  const Claim({
    required this.id,
    required this.listingId,
    required this.claimant,
    required this.answer,
    required this.createdAt,
    this.hasProofPhoto = false,
    this.status = ClaimStatus.pending,
  });

  final String id, listingId;
  final PublicUser claimant;

  /// Free-text answer; visible to the listing author only.
  final String answer;
  final DateTime createdAt;
  final bool hasProofPhoto;
  final ClaimStatus status;

  Claim copyWith({ClaimStatus? status}) => Claim(
        id: id,
        listingId: listingId,
        claimant: claimant,
        answer: answer,
        createdAt: createdAt,
        hasProofPhoto: hasProofPhoto,
        status: status ?? this.status,
      );

  @override
  List<Object?> get props => [id, listingId, claimant, answer, createdAt, hasProofPhoto, status];
}

/// What the would-be owner sees before claiming.
class ClaimTarget extends Equatable {
  const ClaimTarget({required this.listing, required this.attemptsLeft});

  static const maxAttempts = 3;

  final Listing listing;
  final int attemptsLeft;

  @override
  List<Object?> get props => [listing, attemptsLeft];
}

/// Author-only view: the hidden detail next to every claimant's answer.
class ClaimReview extends Equatable {
  const ClaimReview({required this.listing, required this.hiddenDetail, required this.claims});

  final Listing listing;
  final String hiddenDetail;
  final List<Claim> claims;

  int get pendingCount => claims.where((c) => c.status == ClaimStatus.pending).length;

  @override
  List<Object?> get props => [listing, hiddenDetail, claims];
}

class SubmitClaimParams extends Equatable {
  const SubmitClaimParams({required this.listingId, required this.answer, this.hasProofPhoto = false});

  static const minAnswer = 10;

  final String listingId, answer;
  final bool hasProofPhoto;

  @override
  List<Object?> get props => [listingId, answer, hasProofPhoto];
}
