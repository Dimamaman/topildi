import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/links/link_launcher.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/telegram_login.dart';
import '../../domain/usecases/claim_telegram_login.dart';
import '../../domain/usecases/start_telegram_login.dart';

/// [starting]: the button was tapped, the session is being made while the
/// tiles fly in. [waiting]: Telegram is open; the result is checked in the
/// background. [checking]: back from Telegram, the result is being fetched
/// (the radar runs on the page).
enum SignInPhase { idle, starting, waiting, checking }

/// After sign-in: profile setup (new user) or the feed.
enum SignInNext { none, profile, home }

class SignInState extends Equatable {
  const SignInState({this.phase = SignInPhase.idle, this.next = SignInNext.none, this.error, this.offline = false});

  final SignInPhase phase;
  final SignInNext next;

  /// Shown under the button.
  final String? error;

  /// The tap found no network: banner on top, no animation.
  final bool offline;

  SignInState copyWith({SignInPhase? phase, SignInNext? next, String? Function()? error, bool? offline}) => SignInState(
        phase: phase ?? this.phase,
        next: next ?? this.next,
        error: error != null ? error() : this.error,
        offline: offline ?? this.offline,
      );

  @override
  List<Object?> get props => [phase, next, error, offline];
}

/// Sign-in through the Telegram bot, all on the sign-in screen: [begin]
/// starts a server session, [open] opens the bot, then the result is
/// checked every [every] and at once when the app comes back ([resumed]).
/// Coming back before the number was shared returns to [SignInPhase.idle],
/// but checking goes on, so a confirmation that lands a moment later still
/// signs in.
@injectable
class SignInCubit extends Cubit<SignInState> {
  SignInCubit(this._start, this._claim, this._network, this._links) : super(const SignInState());

  static const every = Duration(seconds: 2);

  /// The server session lives 10 minutes.
  static const giveUpAfter = Duration(minutes: 9);

  final StartTelegramLogin _start;
  final ClaimTelegramLogin _claim;
  final NetworkInfo _network;
  final LinkLauncher _links;

  Future<Either<Failure, TelegramLogin>>? _session;
  TelegramLogin? _login;
  Timer? _poll, _deadline;

  /// The claim in flight, shared by the poll and [resumed].
  Future<bool>? _claiming;

  /// False when offline or already busy: the page then leaves the tiles alone.
  Future<bool> begin() async {
    if (state.phase != SignInPhase.idle) return false;
    emit(state.copyWith(phase: SignInPhase.starting, error: () => null, offline: false));
    if (!await _network.isConnected) {
      if (!isClosed) emit(state.copyWith(phase: SignInPhase.idle, offline: true));
      return false;
    }
    _stopChecking();
    _session = _start(const NoParams());
    return true;
  }

  /// Opens the bot once the session is ready. False (with the reason in
  /// [SignInState.error]) when the session failed or Telegram did not open.
  Future<bool> open() async {
    final r = await _session!;
    if (isClosed) return false;
    final login = r.match((f) {
      // No network shows the banner instead of a message.
      emit(state.copyWith(phase: SignInPhase.idle, error: () => f is NetworkFailure ? null : _message(f), offline: f is NetworkFailure));
      return null;
    }, (l) => l);
    if (login == null) return false;
    if (!await _links.open(login.url)) {
      if (!isClosed) emit(state.copyWith(phase: SignInPhase.idle, error: () => tr('Telegramni ochib boʻlmadi. Qayta urinib koʻring')));
      return false;
    }
    if (isClosed) return false;
    _login = login;
    _poll = Timer.periodic(every, (_) => check());
    _deadline = Timer(giveUpAfter, _stopChecking);
    emit(state.copyWith(phase: SignInPhase.waiting));
    return true;
  }

  /// Back from Telegram: check now; still unconfirmed → the tiles come back.
  Future<void> resumed() async {
    if (state.phase != SignInPhase.waiting) return;
    emit(state.copyWith(phase: SignInPhase.checking));
    final signedIn = await check();
    if (!signedIn && !isClosed && state.phase == SignInPhase.checking) emit(state.copyWith(phase: SignInPhase.idle));
  }

  /// True once signed in. Joins a claim already in flight.
  Future<bool> check() {
    final login = _login;
    if (login == null) return Future.value(false);
    return _claiming ??= _claimOnce(login).whenComplete(() => _claiming = null);
  }

  Future<bool> _claimOnce(TelegramLogin login) async {
    final r = await _claim(login);
    if (isClosed || _login != login) return false;
    return r.match(
      (f) {
        // Expired: stop asking. Anything else may pass; keep asking.
        if (f is NotFoundFailure) _stopChecking();
        if (f is! NetworkFailure && f is! NotFoundFailure) debugPrint('Telegram claim failed: ${f.message}');
        return false;
      },
      (result) {
        if (result == null) return false;
        _stopChecking();
        emit(state.copyWith(phase: SignInPhase.idle, next: result.needsProfile ? SignInNext.profile : SignInNext.home));
        return true;
      },
    );
  }

  void _stopChecking() {
    _poll?.cancel();
    _deadline?.cancel();
    _login = null;
  }

  static String _message(Failure f) => switch (f) {
        ValidationFailure(:final message?) => message,
        // Debug builds also show the cause (e.g. a Functions error code).
        _ when kDebugMode && f.message != null => '${tr('Kirishda xatolik yuz berdi')}\n${f.message}',
        _ => tr('Kirishda xatolik yuz berdi'),
      };

  @override
  Future<void> close() {
    _stopChecking();
    return super.close();
  }
}
