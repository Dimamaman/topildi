import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/usecases/request_sms_code.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../../../core/l10n/tr.dart';

/// After a successful step: SMS code screen, profile setup (new user) or the feed.
enum SignInNext { none, code, profile, home }

class SignInState extends Equatable {
  const SignInState({this.input = '', this.showError = false, this.loading = false, this.next = SignInNext.none, this.failure});

  final String input;
  final bool showError, loading;
  final SignInNext next;
  final Failure? failure;

  PhoneNumber? get phone => PhoneNumber.tryParse(input);

  String? get error {
    if (!showError || phone != null) return null;
    final n = input.replaceAll(RegExp(r'\D'), '').length;
    return tr('Raqam toʻliq emas: {n} ta raqam kiriting{progress}', {'n': PhoneNumber.length, 'progress': n > 0 ? ' ($n/${PhoneNumber.length})' : ''});
  }

  SignInState copyWith({String? input, bool? showError, bool? loading, SignInNext? next, Failure? failure}) => SignInState(
        input: input ?? this.input,
        showError: showError ?? this.showError,
        loading: loading ?? this.loading,
        next: next ?? SignInNext.none,
        failure: failure,
      );

  @override
  List<Object?> get props => [input, showError, loading, next, failure];
}

@injectable
class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._request, this._google) : super(const SignInState());

  final RequestSmsCode _request;
  final SignInWithGoogle _google;

  void setInput(String v) => emit(state.copyWith(input: v));

  Future<void> requestCode() async {
    final phone = state.phone;
    emit(state.copyWith(showError: true));
    if (phone == null || state.loading) return;
    emit(state.copyWith(loading: true));
    final r = await _request(phone);
    if (isClosed) return;
    r.match(
      (f) => emit(state.copyWith(loading: false, failure: f)),
      (_) => emit(state.copyWith(loading: false, next: SignInNext.code)),
    );
  }

  Future<void> google() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true));
    final r = await _google(const NoParams());
    if (isClosed) return;
    r.match(
      (f) => emit(state.copyWith(loading: false, failure: f)),
      (r) => emit(state.copyWith(loading: false, next: r.needsProfile ? SignInNext.profile : SignInNext.home)),
    );
  }
}
