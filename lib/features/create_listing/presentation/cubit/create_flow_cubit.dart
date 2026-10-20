import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/create_draft.dart';
import '../../domain/usecases/post_listing.dart';

enum SubmitStatus { idle, submitting, success, failure }

class CreateFlowState extends Equatable {
  const CreateFlowState({
    this.draft = const CreateDraft(),
    this.showDetailErrors = false,
    this.showAreaError = false,
    this.agreed = true,
    this.status = SubmitStatus.idle,
    this.postedId,
    this.failure,
  });

  final CreateDraft draft;

  /// Errors are shown only after the user tried to continue.
  final bool showDetailErrors, showAreaError;
  final bool agreed;
  final SubmitStatus status;
  final String? postedId;
  final Failure? failure;

  CreateFlowState copyWith({
    CreateDraft? draft,
    bool? showDetailErrors,
    bool? showAreaError,
    bool? agreed,
    SubmitStatus? status,
    String? postedId,
    Failure? failure,
  }) =>
      CreateFlowState(
        draft: draft ?? this.draft,
        showDetailErrors: showDetailErrors ?? this.showDetailErrors,
        showAreaError: showAreaError ?? this.showAreaError,
        agreed: agreed ?? this.agreed,
        status: status ?? this.status,
        postedId: postedId ?? this.postedId,
        failure: failure,
      );

  @override
  List<Object?> get props => [draft, showDetailErrors, showAreaError, agreed, status, postedId, failure];
}

@injectable
class CreateFlowCubit extends Cubit<CreateFlowState> {
  CreateFlowCubit(this._postListing) : super(const CreateFlowState());

  final PostListing _postListing;
  int _nextTint = 0;

  void _draft(CreateDraft Function(CreateDraft d) update) => emit(state.copyWith(draft: update(state.draft)));

  // Step 1
  void setType(ListingType type) => _draft((d) => d.copyWith(type: type));

  void addPhoto() {
    if (state.draft.photoTints.length >= CreateDraft.maxPhotos) return;
    _draft((d) => d.copyWith(photoTints: [...d.photoTints, _nextTint++ % 4]));
  }

  void removePhoto(int index) => _draft((d) => d.copyWith(photoTints: [...d.photoTints]..removeAt(index)));

  // Step 2
  void setTitle(String v) => _draft((d) => d.copyWith(title: v));
  void setCategory(ItemCategory v) => _draft((d) => d.copyWith(category: v));
  void setDescription(String v) => _draft((d) => d.copyWith(description: v));
  void setHiddenDetail(String v) => _draft((d) => d.copyWith(hiddenDetail: v));

  /// Returns true when step 2 can be left.
  bool submitDetails() {
    emit(state.copyWith(showDetailErrors: true));
    return DraftValidator.detailsValid(state.draft);
  }

  // Step 3
  void setArea(String area) => _draft((d) => d.copyWith(areaName: area));
  void setDay(DraftDay day, {DateTime? date}) => _draft((d) => d.copyWith(day: day, date: date));
  void setTime(int hour, int minute) => _draft((d) => d.copyWith(hour: hour, minute: minute));

  bool submitLocation() {
    emit(state.copyWith(showAreaError: true));
    return DraftValidator.area(state.draft) == null;
  }

  // Review
  void setAgreed(bool v) => emit(state.copyWith(agreed: v));

  Future<void> publish() async {
    if (!state.agreed || state.status == SubmitStatus.submitting) return;
    emit(state.copyWith(status: SubmitStatus.submitting));
    final result = await _postListing(state.draft);
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(status: SubmitStatus.failure, failure: f)),
      (id) => emit(state.copyWith(status: SubmitStatus.success, postedId: id)),
    );
  }
}
