import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/telegram_login.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/start_telegram_login.dart';

/// After a successful step: the Telegram wait screen, profile setup (new user) or the feed.
enum SignInNext { none, telegram, profile, home }

class SignInState extends Equatable {
  const SignInState({this.loading = false, this.next = SignInNext.none, this.login, this.failure});

  final bool loading;
  final SignInNext next;

  /// Set with [SignInNext.telegram].
  final TelegramLogin? login;
  final Failure? failure;

  SignInState copyWith({bool? loading, SignInNext? next, TelegramLogin? login, Failure? failure}) => SignInState(
        loading: loading ?? this.loading,
        next: next ?? SignInNext.none,
        login: login,
        failure: failure,
      );

  @override
  List<Object?> get props => [loading, next, login, failure];
}

@injectable
class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._telegram, this._google) : super(const SignInState());

  final StartTelegramLogin _telegram;
  final SignInWithGoogle _google;

  Future<void> telegram() async {
    if (state.loading) return;
    emit(state.copyWith(loading: true));
    final r = await _telegram(const NoParams());
    if (isClosed) return;
    r.match(
      (f) => emit(state.copyWith(loading: false, failure: f)),
      (login) => emit(state.copyWith(loading: false, next: SignInNext.telegram, login: login)),
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
