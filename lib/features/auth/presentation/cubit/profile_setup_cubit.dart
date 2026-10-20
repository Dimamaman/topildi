import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/session/session.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/usecases/save_profile.dart';

class ProfileSetupState extends Equatable {
  const ProfileSetupState({this.first = '', this.last = '', this.hasPhoto = false, this.saving = false, this.showError = false, this.done = false, this.failed = false});

  final String first, last;
  final bool hasPhoto, saving, showError, done, failed;

  String? get firstError => showError && first.trim().length < 2 ? 'Ismingizni kiriting' : null;

  /// Preview of what other users will see.
  String get publicName => first.trim().isEmpty ? 'Malika K.' : Session.publicName(first, last);

  ProfileSetupState copyWith({String? first, String? last, bool? hasPhoto, bool? saving, bool? showError, bool? done, bool? failed}) =>
      ProfileSetupState(
        first: first ?? this.first,
        last: last ?? this.last,
        hasPhoto: hasPhoto ?? this.hasPhoto,
        saving: saving ?? this.saving,
        showError: showError ?? this.showError,
        done: done ?? this.done,
        failed: failed ?? false,
      );

  @override
  List<Object?> get props => [first, last, hasPhoto, saving, showError, done, failed];
}

@injectable
class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit(this._save, this._session) : super(const ProfileSetupState());

  final SaveProfile _save;
  final Session _session;

  void prefill() => emit(state.copyWith(first: _session.firstName, last: _session.lastName));

  void setFirst(String v) => emit(state.copyWith(first: v));
  void setLast(String v) => emit(state.copyWith(last: v));
  void togglePhoto() => emit(state.copyWith(hasPhoto: !state.hasPhoto));

  Future<void> submit() async {
    emit(state.copyWith(showError: true));
    if (state.firstError != null || state.saving) return;
    emit(state.copyWith(saving: true));
    final r = await _save(ProfileInput(firstName: state.first, lastName: state.last, hasPhoto: state.hasPhoto));
    if (isClosed) return;
    r.match(
      (_) => emit(state.copyWith(saving: false, failed: true)),
      (_) => emit(state.copyWith(saving: false, done: true)),
    );
  }
}
