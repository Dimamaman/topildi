import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/location/geo_point.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/domain/entities/regions.dart';
import '../../domain/entities/create_draft.dart';
import '../../domain/usecases/post_listing.dart';

enum SubmitStatus { idle, submitting, success, failure }

class CreateFlowState extends Equatable {
  const CreateFlowState({
    this.draft = const CreateDraft(),
    this.showDetailErrors = false,
    this.showAreaError = false,
    this.attempt = 0,
    this.status = SubmitStatus.idle,
    this.postedId,
    this.failure,
  });

  final CreateDraft draft;

  /// Errors are shown only after the user tried to continue.
  final bool showDetailErrors, showAreaError;

  /// Bumped on every refused "Keyingi": the step then scrolls to its first error.
  final int attempt;
  final SubmitStatus status;
  final String? postedId;
  final Failure? failure;

  CreateFlowState copyWith({
    CreateDraft? draft,
    bool? showDetailErrors,
    bool? showAreaError,
    int? attempt,
    SubmitStatus? status,
    String? postedId,
    Failure? failure,
  }) =>
      CreateFlowState(
        draft: draft ?? this.draft,
        showDetailErrors: showDetailErrors ?? this.showDetailErrors,
        showAreaError: showAreaError ?? this.showAreaError,
        attempt: attempt ?? this.attempt,
        status: status ?? this.status,
        postedId: postedId ?? this.postedId,
        failure: failure,
      );

  @override
  List<Object?> get props => [draft, showDetailErrors, showAreaError, attempt, status, postedId, failure];
}

@injectable
class CreateFlowCubit extends Cubit<CreateFlowState> {
  CreateFlowCubit(this._postListing) : super(_initial(DateTime.now()));

  /// The time defaults to now.
  static CreateFlowState _initial(DateTime now) =>
      CreateFlowState(draft: CreateDraft(hour: now.hour, minute: now.minute));

  final PostListing _postListing;

  void _draft(CreateDraft Function(CreateDraft d) update) => emit(state.copyWith(draft: update(state.draft)));

  // Step 1
  void setType(ListingType type) => _draft((d) => d.copyWith(type: type));

  void addPhoto(String path) {
    if (state.draft.photos.length >= CreateDraft.maxPhotos) return;
    _draft((d) => d.copyWith(photos: [...d.photos, path]));
  }

  void removePhoto(int index) => _draft((d) => d.copyWith(photos: [...d.photos]..removeAt(index)));

  /// Long-press reorder; the first photo is the main one.
  void movePhoto(int from, int to) => _draft((d) {
        final photos = [...d.photos];
        photos.insert(to, photos.removeAt(from));
        return d.copyWith(photos: photos);
      });

  // Step 2
  void setTitle(String v) => _draft((d) => d.copyWith(title: v));
  void setCategory(ItemCategory v) => _draft((d) => d.copyWith(category: v));
  void setHiddenDetail(String v) => _draft((d) => d.copyWith(hiddenDetail: v));

  /// Returns true when step 2 can be left.
  bool submitDetails() {
    final ok = DraftValidator.detailsValid(state.draft);
    emit(state.copyWith(showDetailErrors: true, attempt: ok ? null : state.attempt + 1));
    return ok;
  }

  /// A step opens without errors; they show again only after "Keyingi".
  void hideErrors() => emit(state.copyWith(showDetailErrors: false, showAreaError: false));

  // Step 3
  /// [point] is the GPS position from "Aniqlash"; otherwise the district centre.
  void setDistrict(String district, {GeoPoint? point}) {
    final (lat, lng) = Regions.tashkentDistrictCenters[district]!;
    _draft((d) => d.copyWith(district: district, point: (point ?? GeoPoint(lat, lng)).approximate()));
  }

  void setLandmark(String v) => _draft((d) => d.copyWith(landmark: v));
  void setDay(DraftDay day, {DateTime? date}) => _draft((d) => d.copyWith(day: day, date: date));
  void setTime(int hour, int minute) => _draft((d) => d.copyWith(hour: hour, minute: minute));

  bool submitLocation() {
    final ok = DraftValidator.district(state.draft) == null;
    emit(state.copyWith(showAreaError: true, attempt: ok ? null : state.attempt + 1));
    return ok;
  }

  // Review
  Future<void> publish() async {
    if (state.status == SubmitStatus.submitting) return;
    emit(state.copyWith(status: SubmitStatus.submitting));
    final result = await _postListing(state.draft);
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(status: SubmitStatus.failure, failure: f)),
      (id) => emit(state.copyWith(status: SubmitStatus.success, postedId: id)),
    );
  }
}
