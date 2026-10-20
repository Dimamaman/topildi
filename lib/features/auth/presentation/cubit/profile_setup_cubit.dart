import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/session/session.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/usecases/save_profile.dart';

class ProfileSetupState extends Equatable {
  const ProfileSetupState({this.first = '', this.last = '', this.photoPath, this.saving = false, this.showError = false, this.done = false, this.failed = false});

  final String first, last;
  final String? photoPath;
  final bool saving, showError, done, failed;

  bool get hasPhoto => photoPath != null;

  String? get firstError => showError && first.trim().length < 2 ? 'Ismingizni kiriting' : null;

  /// Preview of what other users will see.
  String get publicName => first.trim().isEmpty ? 'Malika K.' : Session.publicName(first, last);

  ProfileSetupState copyWith({String? first, String? last, String? Function()? photoPath, bool? saving, bool? showError, bool? done, bool? failed}) =>
      ProfileSetupState(
        first: first ?? this.first,
        last: last ?? this.last,
        photoPath: photoPath != null ? photoPath() : this.photoPath,
        saving: saving ?? this.saving,
        showError: showError ?? this.showError,
        done: done ?? this.done,
        failed: failed ?? false,
      );

  @override
  List<Object?> get props => [first, last, photoPath, saving, showError, done, failed];
}

@injectable
class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit(this._save, this._session) : super(const ProfileSetupState());

  final SaveProfile _save;
  final Session _session;

  void prefill() =>
      emit(state.copyWith(first: _session.firstName, last: _session.lastName, photoPath: () => _session.avatarPath));

  void setFirst(String v) => emit(state.copyWith(first: v));
  void setLast(String v) => emit(state.copyWith(last: v));
  void setPhoto(String? path) => emit(state.copyWith(photoPath: () => path));

  Future<void> submit() async {
    emit(state.copyWith(showError: true));
    if (state.firstError != null || state.saving) return;
    emit(state.copyWith(saving: true));
    final r = await _save(ProfileInput(firstName: state.first, lastName: state.last, photoPath: state.photoPath));
    if (isClosed) return;
    r.match(
      (_) => emit(state.copyWith(saving: false, failed: true)),
      (_) => emit(state.copyWith(saving: false, done: true)),
    );
  }
}
