import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/session/session.dart';
import '../../../../core/view_state.dart';
import '../../../claim/domain/usecases/cancel_claim.dart';
import '../../../claim/domain/usecases/get_claim_review.dart';
import '../../../claim/domain/usecases/get_claim_target.dart';
import '../../domain/entities/listing.dart';
import '../../domain/usecases/get_listing_detail.dart';
import '../../domain/usecases/manage_listing.dart';

class DetailState extends Equatable {
  const DetailState({
    this.view = const ViewLoading(),
    this.photoIndex = 0,
    this.isMine = false,
    this.pendingClaims = 0,
    this.claimSent = false,
    this.claimSentAt,
    this.deleted = false,
    this.busy = false,
  });

  final ViewState<Listing> view;
  final int photoIndex;

  /// The signed-in user authored this listing (shows claims instead of "Bu meniki").
  final bool isMine;

  /// Author: claims waiting for an answer.
  final int pendingClaims;

  /// Visitor: already sent a claim that is still waiting.
  final bool claimSent;

  /// Visitor: when that waiting claim was sent.
  final DateTime? claimSentAt;

  /// Author deleted the listing; the page should close.
  final bool deleted;

  /// Delete / mark-returned in flight.
  final bool busy;

  DetailState copyWith({
    ViewState<Listing>? view,
    int? photoIndex,
    bool? isMine,
    int? pendingClaims,
    bool? claimSent,
    DateTime? Function()? claimSentAt,
    bool? deleted,
    bool? busy,
  }) => DetailState(
    view: view ?? this.view,
    photoIndex: photoIndex ?? this.photoIndex,
    isMine: isMine ?? this.isMine,
    pendingClaims: pendingClaims ?? this.pendingClaims,
    claimSent: claimSent ?? this.claimSent,
    claimSentAt: claimSentAt != null ? claimSentAt() : this.claimSentAt,
    deleted: deleted ?? this.deleted,
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [view, photoIndex, isMine, pendingClaims, claimSent, claimSentAt, deleted, busy];
}

@injectable
class DetailCubit extends Cubit<DetailState> {
  DetailCubit(
    this._getDetail,
    this._session,
    this._getReview,
    this._getTarget,
    this._delete,
    this._markReturned,
    this._cancelClaim,
  ) : super(const DetailState());

  final GetListingDetail _getDetail;
  final Session _session;
  final GetClaimReview _getReview;
  final GetClaimTarget _getTarget;
  final DeleteListing _delete;
  final MarkListingReturned _markReturned;
  final CancelClaim _cancelClaim;

  /// Visitor: takes back the unanswered claim. Returns the failure, if any.
  Future<Failure?> cancelClaim() async {
    final view = state.view;
    if (view is! ViewLoaded<Listing>) return null;
    final r = await _cancelClaim(view.data.id);
    if (isClosed) return null;
    return r.match((f) => f, (_) {
      emit(state.copyWith(claimSent: false, claimSentAt: () => null));
      return null;
    });
  }

  Future<void> load(String id) async {
    emit(state.copyWith(view: const ViewLoading()));
    final result = await _getDetail(id);
    if (isClosed) return;
    await result.match((f) async => emit(state.copyWith(view: ViewError(f))), (l) async {
      final mine = l.author.id == _session.userId;
      emit(state.copyWith(view: ViewLoaded(l), isMine: mine));
      await refreshClaims();
    });
  }

  /// Pending-claims count (author) or "already sent" (visitor). Errors keep
  /// the previous values; the page still works without them.
  Future<void> refreshClaims() async {
    final view = state.view;
    if (view is! ViewLoaded<Listing>) return;
    final id = view.data.id;
    if (state.isMine) {
      final r = await _getReview(id);
      if (isClosed) return;
      r.match((_) {}, (review) => emit(state.copyWith(pendingClaims: review.pendingCount)));
    } else {
      final r = await _getTarget(id);
      if (isClosed) return;
      r.match((_) {}, (t) => emit(state.copyWith(claimSent: t.hasPending, claimSentAt: () => t.pendingSince)));
    }
  }

  void selectPhoto(int index) => emit(state.copyWith(photoIndex: index));

  /// Returns the failure, if any, so the page can show it.
  Future<Failure?> delete() async {
    final view = state.view;
    if (view is! ViewLoaded<Listing> || state.busy) return null;
    emit(state.copyWith(busy: true));
    final r = await _delete(view.data.id);
    if (isClosed) return null;
    return r.match(
      (f) {
        emit(state.copyWith(busy: false));
        return f;
      },
      (_) {
        emit(state.copyWith(busy: false, deleted: true));
        return null;
      },
    );
  }

  Future<Failure?> markReturned() async {
    final view = state.view;
    if (view is! ViewLoaded<Listing> || state.busy) return null;
    emit(state.copyWith(busy: true));
    final r = await _markReturned(view.data.id);
    if (isClosed) return null;
    return r.match(
      (f) {
        emit(state.copyWith(busy: false));
        return f;
      },
      (l) {
        emit(state.copyWith(busy: false, view: ViewLoaded(l)));
        return null;
      },
    );
  }
}
