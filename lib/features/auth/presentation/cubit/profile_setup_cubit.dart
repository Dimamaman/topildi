import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/session/session.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../profile/domain/usecases/profile_usecases.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/usecases/save_profile.dart';
import '../../../../core/l10n/tr.dart';

class ProfileSetupState extends Equatable {
  const ProfileSetupState({
    this.first = '',
    this.photoPath,
    this.tone = 0,
    this.emoji,
    this.saving = false,
    this.showError = false,
    this.done = false,
    this.failed = false,
    this.offline = false,
  });

  final String first;
  final String? photoPath;

  /// Letter-avatar colour: 0 primary, 1 green, 2 peach, 3 yellow.
  final int tone;

  /// Emoji avatar (mutually exclusive with a photo).
  final String? emoji;
  final bool saving, showError, done, failed, offline;

  bool get hasPhoto => photoPath != null;

  /// "Tayyor" is enabled once something is typed.
  bool get canSubmit => first.trim().isNotEmpty;

  String? get firstError => showError && first.trim().length < 2 ? tr('Ismingizni kiriting') : null;

  /// What other users will see. No surname is asked for, so the name alone.
  String get publicName => first.trim();

  ProfileSetupState copyWith({
    String? first,
    String? Function()? photoPath,
    int? tone,
    String? Function()? emoji,
    bool? saving,
    bool? showError,
    bool? done,
    bool? failed,
    bool? offline,
  }) => ProfileSetupState(
    first: first ?? this.first,
    photoPath: photoPath != null ? photoPath() : this.photoPath,
    tone: tone ?? this.tone,
    emoji: emoji != null ? emoji() : this.emoji,
    saving: saving ?? this.saving,
    showError: showError ?? this.showError,
    done: done ?? this.done,
    failed: failed ?? false,
    offline: offline ?? false,
  );

  @override
  List<Object?> get props => [first, photoPath, tone, emoji, saving, showError, done, failed, offline];
}

@injectable
class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit(this._save, this._session, this._deleteAccount) : super(const ProfileSetupState());

  final SaveProfile _save;
  final Session _session;
  final DeleteAccount _deleteAccount;

  /// "Hisobni oʻchirish" (editing only); null once the account is gone.
  Future<Failure?> deleteAccount() async => (await _deleteAccount(const NoParams())).fold((f) => f, (_) => null);

  void prefill() => emit(
    state.copyWith(
      first: _session.firstName,
      photoPath: () => _session.avatarPath,
      tone: _session.avatarTone,
      emoji: () => _session.avatarEmoji,
    ),
  );

  void setFirst(String v) => emit(state.copyWith(first: v));

  /// A photo replaces the emoji.
  void setPhoto(String? path) => emit(state.copyWith(photoPath: () => path, emoji: path == null ? null : () => null));

  /// An emoji replaces the photo.
  void setEmoji(String? emoji) =>
      emit(state.copyWith(emoji: () => emoji, photoPath: emoji == null ? null : () => null));

  /// Tapping the selected colour again goes back to the default blue.
  void toggleTone(int tone) => emit(state.copyWith(tone: state.tone == tone ? 0 : tone));

  Future<void> submit() async {
    emit(state.copyWith(showError: true));
    if (state.firstError != null || state.saving) return;
    emit(state.copyWith(saving: true));
    final r = await _save(
      ProfileInput(
        firstName: state.first,
        // Surname is no longer asked for; clear any old one.
        lastName: '',
        photoPath: state.photoPath,
        tone: state.tone,
        emoji: state.emoji,
      ),
    );
    if (isClosed) return;
    r.match(
      (f) => emit(state.copyWith(saving: false, failed: f is! NetworkFailure, offline: f is NetworkFailure)),
      (_) => emit(state.copyWith(saving: false, done: true)),
    );
  }
}
