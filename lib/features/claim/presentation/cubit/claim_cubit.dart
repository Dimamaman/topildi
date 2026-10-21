import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/view_state.dart';
import '../../domain/entities/claim.dart';
import '../../domain/usecases/get_claim_target.dart';
import '../../domain/usecases/submit_claim.dart';
import '../../../../core/l10n/tr.dart';

class ClaimState extends Equatable {
  const ClaimState({
    this.view = const ViewLoading(),
    this.answer = '',
    this.proofPath,
    this.submitting = false,
    this.showError = false,
    this.submitFailure,
    this.sent = false,
  });

  final ViewState<ClaimTarget> view;
  final String answer;
  final String? proofPath;
  final bool submitting, showError, sent;

  bool get hasProofPhoto => proofPath != null;
  final Failure? submitFailure;

  String? get answerError => showError && answer.trim().length < SubmitClaimParams.minAnswer
      ? tr('Javobni batafsilroq yozing (kamida {minAnswer} ta belgi)', {'minAnswer': SubmitClaimParams.minAnswer})
      : null;

  ClaimState copyWith({
    ViewState<ClaimTarget>? view,
    String? answer,
    String? Function()? proofPath,
    bool? submitting,
    bool? showError,
    Failure? submitFailure,
    bool? sent,
  }) =>
      ClaimState(
        view: view ?? this.view,
        answer: answer ?? this.answer,
        proofPath: proofPath != null ? proofPath() : this.proofPath,
        submitting: submitting ?? this.submitting,
        showError: showError ?? this.showError,
        submitFailure: submitFailure,
        sent: sent ?? this.sent,
      );

  @override
  List<Object?> get props => [view, answer, proofPath, submitting, showError, submitFailure, sent];
}

@injectable
class ClaimCubit extends Cubit<ClaimState> {
  ClaimCubit(this._getTarget, this._submit) : super(const ClaimState());

  final GetClaimTarget _getTarget;
  final SubmitClaim _submit;
  late String _listingId;

  Future<void> load(String listingId) async {
    _listingId = listingId;
    emit(state.copyWith(view: const ViewLoading()));
    final result = await _getTarget(listingId);
    if (isClosed) return;
    emit(state.copyWith(view: result.fold<ViewState<ClaimTarget>>((f) => ViewError(f), ViewLoaded.new)));
  }

  void setAnswer(String v) => emit(state.copyWith(answer: v));

  void setProofPhoto(String? path) => emit(state.copyWith(proofPath: () => path));

  Future<void> submit() async {
    if (state.submitting) return;
    emit(state.copyWith(showError: true));
    if (state.answerError != null) return;
    emit(state.copyWith(submitting: true));
    final result = await _submit(
      SubmitClaimParams(listingId: _listingId, answer: state.answer, proofPath: state.proofPath),
    );
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(submitting: false, submitFailure: f)),
      (_) => emit(state.copyWith(submitting: false, sent: true)),
    );
  }
}
