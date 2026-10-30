import 'package:equatable/equatable.dart';

import '../../../listing/domain/entities/listing.dart';

/// What a shikoyat is about. The name goes into the document's id
/// (`{targetType}_{targetId}_{reporterUid}`), so it never changes.
enum ReportTargetType { listing, chat }

/// Why. `fake` reads "Soxta eʼlon" on a listing and "Aldov" in a chat.
enum ReportReason { spam, fake, scam, offensive, other }

/// Longest optional note the moderator gets (also in firestore.rules).
const maxReportComment = 300;

/// The listing or the chat being reported, with what the sheet shows at the
/// top: a thumbnail, the title and who is reported.
class ReportTarget extends Equatable {
  const ReportTarget({
    required this.type,
    required this.id,
    required this.reportedUid,
    required this.title,
    required this.personName,
    this.photoUrl,
    this.category = ItemCategory.other,
    this.tint = 0,
  });

  ReportTarget.listing(Listing listing)
    : type = ReportTargetType.listing,
      id = listing.id,
      reportedUid = listing.author.id,
      title = listing.title,
      personName = listing.author.displayName,
      photoUrl = listing.photos.isEmpty ? null : listing.photos.first,
      category = listing.category,
      tint = listing.tint;

  final ReportTargetType type;

  /// Listing id, or chat id.
  final String id;

  /// Who is reported: the listing's author, or the other chat member.
  final String reportedUid;

  final String title;

  /// Shown after "Eʼlon · " / "Chat · ".
  final String personName;

  /// Listing photo for the thumbnail; the category tile stands in for it.
  final String? photoUrl;
  final ItemCategory category;
  final int tint;

  @override
  List<Object?> get props => [type, id, reportedUid, title, personName, photoUrl, category, tint];
}

class SubmitReportParams extends Equatable {
  const SubmitReportParams({required this.target, required this.reason, this.comment = ''});

  final ReportTarget target;
  final ReportReason reason;
  final String comment;

  @override
  List<Object?> get props => [target, reason, comment];
}
