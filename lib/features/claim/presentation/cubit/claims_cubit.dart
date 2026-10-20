import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/view_state.dart';
import '../../domain/entities/claim.dart';
import '../../domain/usecases/accept_claim.dart';
import '../../domain/usecases/get_claim_review.dart';
import '../../domain/usecases/reject_claim.dart';

class ClaimsState extends Equatable {
  const ClaimsState({this.view = const ViewLoading(), this.busyId, this.openedChatId, this.actionFailure});

  final ViewState<ClaimReview> view;

  /// Claim currently being accepted/rejected.
  final String? busyId;

  /// Set once after accepting, so the page can navigate to the chat.
  final String? openedChatId;
  final Failure? actionFailure;

  ClaimsState copyWith({
    ViewState<ClaimReview>? view,
    String? Function()? busyId,
    String? openedChatId,
    Failure? actionFailure,
  }) =>
      ClaimsState(
        view: view ?? this.view,
        busyId: busyId != null ? busyId() : this.busyId,
        openedChatId: openedChatId,
        actionFailure: actionFailure,
      );

  @override
  List<Object?> get props => [view, busyId, openedChatId, actionFailure];
}

@injectable
class ClaimsCubit extends Cubit<ClaimsState> {
  ClaimsCubit(this._getReview, this._accept, this._reject) : super(const ClaimsState());

  final GetClaimReview _getReview;
  final AcceptClaim _accept;
  final RejectClaim _reject;
  late String _listingId;

  Future<void> load(String listingId) async {
    _listingId = listingId;
    emit(state.copyWith(view: const ViewLoading()));
    await _refresh();
  }

  Future<void> _refresh() async {
    final result = await _getReview(_listingId);
    if (isClosed) return;
    emit(state.copyWith(
      busyId: () => null,
      view: result.fold<ViewState<ClaimReview>>(
        (f) => ViewError(f),
        (r) => r.claims.isEmpty ? const ViewEmpty() : ViewLoaded(r),
      ),
    ));
  }

  Future<void> accept(String claimId) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: () => claimId));
    final result = await _accept(claimId);
    if (isClosed) return;
    await result.match(
      (f) async => emit(state.copyWith(busyId: () => null, actionFailure: f)),
      (chatId) async {
        await _refresh();
        if (!isClosed) emit(state.copyWith(openedChatId: chatId));
      },
    );
  }

  Future<void> reject(String claimId) async {
    if (state.busyId != null) return;
    emit(state.copyWith(busyId: () => claimId));
    final result = await _reject(claimId);
    if (isClosed) return;
    await result.match(
      (f) async => emit(state.copyWith(busyId: () => null, actionFailure: f)),
      (_) => _refresh(),
    );
  }
}
