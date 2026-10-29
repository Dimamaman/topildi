import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/location/geo_point.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/domain/entities/regions.dart';
import '../../domain/entities/create_draft.dart';
import '../../domain/usecases/post_listing.dart';
import '../../domain/usecases/update_listing.dart';
import '../../../claim/domain/usecases/get_claim_review.dart';

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
    this.editingId,
    this.original,
    this.hiddenLocked = false,
  });

  final CreateDraft draft;

  /// Errors are shown only after the user tried to continue.
  final bool showDetailErrors, showAreaError;

  /// Bumped on every refused "Keyingi": the step then scrolls to its first error.
  final int attempt;
  final SubmitStatus status;
  final String? postedId;
  final Failure? failure;

  /// Editing this existing listing instead of posting a new one.
  final String? editingId;

  /// The listing as loaded for editing: [draft] differs → unsaved changes.
  final CreateDraft? original;

  /// Requests already came in: the hidden detail can't change any more,
  /// or their answers would be checked against a new one.
  final bool hiddenLocked;

  bool get isEditing => editingId != null;
  bool get hasChanges => original != null && original != draft;

  CreateFlowState copyWith({
    CreateDraft? draft,
    bool? showDetailErrors,
    bool? showAreaError,
    int? attempt,
    SubmitStatus? status,
    String? postedId,
    Failure? failure,
    String? editingId,
    CreateDraft? original,
    bool? hiddenLocked,
  }) =>
      CreateFlowState(
        draft: draft ?? this.draft,
        showDetailErrors: showDetailErrors ?? this.showDetailErrors,
        showAreaError: showAreaError ?? this.showAreaError,
        attempt: attempt ?? this.attempt,
        status: status ?? this.status,
        postedId: postedId ?? this.postedId,
        failure: failure,
        editingId: editingId ?? this.editingId,
        original: original ?? this.original,
        hiddenLocked: hiddenLocked ?? this.hiddenLocked,
      );

  @override
  List<Object?> get props =>
      [draft, showDetailErrors, showAreaError, attempt, status, postedId, failure, editingId, original, hiddenLocked];
}

@injectable
class CreateFlowCubit extends Cubit<CreateFlowState> {
  CreateFlowCubit(this._postListing, this._updateListing, this._getReview) : super(_initial(DateTime.now()));

  /// The time defaults to now.
  static CreateFlowState _initial(DateTime now) =>
      CreateFlowState(draft: CreateDraft(hour: now.hour, minute: now.minute));

  final PostListing _postListing;
  final UpdateListing _updateListing;
  final GetClaimReview _getReview;

  /// Loads listing [id] (with its hidden detail and requests) for editing.
  /// Returns the failure, if any.
  Future<Failure?> startEdit(String id) async {
    final r = await _getReview(id);
    if (isClosed) return null;
    return r.match((f) => f, (review) {
      final draft = draftOf(review.listing, review.hiddenDetail, DateTime.now());
      emit(CreateFlowState(draft: draft, original: draft, editingId: id, hiddenLocked: review.claims.isNotEmpty));
      return null;
    });
  }

  /// The draft that an existing listing was posted from.
  static CreateDraft draftOf(Listing l, String hiddenDetail, DateTime now) {
    final at = l.happenedAt;
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final prefix = '${l.district}, ';
    return CreateDraft(
      type: l.type,
      photos: l.photos,
      title: l.title,
      category: l.category,
      hiddenDetail: hiddenDetail,
      landmark: l.areaName.startsWith(prefix) ? l.areaName.substring(prefix.length) : '',
      city: l.city,
      point: GeoPoint(l.lat, l.lng),
      district: l.district,
      day: day == today
          ? DraftDay.today
          : day == today.subtract(const Duration(days: 1))
          ? DraftDay.yesterday
          : DraftDay.other,
      date: day == today ? null : day,
      hour: at.hour,
      minute: at.minute,
    );
  }

  /// Saves the edit. Returns the failure, if any.
  Future<Failure?> save() async {
    final id = state.editingId;
    if (id == null || state.status == SubmitStatus.submitting) return null;
    emit(state.copyWith(status: SubmitStatus.submitting));
    final r = await _updateListing(UpdateListingParams(id: id, draft: state.draft, hiddenDetail: !state.hiddenLocked));
    if (isClosed) return null;
    return r.match(
      (f) {
        emit(state.copyWith(status: SubmitStatus.failure, failure: f));
        return f;
      },
      (_) {
        emit(state.copyWith(status: SubmitStatus.success, original: state.draft));
        return null;
      },
    );
  }

  void _draft(CreateDraft Function(CreateDraft d) update) => emit(state.copyWith(draft: update(state.draft)));

  // Step 1
  /// Fixed once posted.
  void setType(ListingType type) {
    if (!state.isEditing) _draft((d) => d.copyWith(type: type));
  }

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
  void setHiddenDetail(String v) {
    if (!state.hiddenLocked) _draft((d) => d.copyWith(hiddenDetail: v));
  }

  /// Returns true when step 2 can be left.
  bool submitDetails() {
    final ok = DraftValidator.detailsValid(state.draft);
    emit(state.copyWith(showDetailErrors: true, attempt: ok ? null : state.attempt + 1));
    return ok;
  }

  /// A step opens without errors; they show again only after "Keyingi".
  void hideErrors() => emit(state.copyWith(showDetailErrors: false, showAreaError: false));

  // Step 3
  /// Changing the region clears the district.
  void setCity(String city) {
    if (city != state.draft.city) _draft((d) => d.withCity(city));
  }

  /// [point] is the GPS position from "Aniqlash"; otherwise the district
  /// centre (the region centre outside Tashkent).
  void setDistrict(String district, {GeoPoint? point}) => _draft(
    (d) => d.copyWith(district: district, point: (point ?? Regions.pointOf(d.city, district)).approximate()),
  );

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
