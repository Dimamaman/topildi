import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/telegram_login.dart';
import '../../domain/usecases/claim_telegram_login.dart';

enum TelegramWaitStatus { waiting, verified, expired }

class TelegramWaitState extends Equatable {
  const TelegramWaitState({this.status = TelegramWaitStatus.waiting, this.needsProfile = true, this.offline = false});

  final TelegramWaitStatus status;

  /// After [TelegramWaitStatus.verified]: new users fill in the profile, returning ones go home.
  final bool needsProfile;

  /// The last check failed for lack of network; checking goes on.
  final bool offline;

  TelegramWaitState copyWith({TelegramWaitStatus? status, bool? needsProfile, bool? offline}) => TelegramWaitState(
        status: status ?? this.status,
        needsProfile: needsProfile ?? this.needsProfile,
        offline: offline ?? this.offline,
      );

  @override
  List<Object?> get props => [status, needsProfile, offline];
}

/// Asks the server every [every] whether the number was shared in Telegram
/// (and at once when the app comes back to the front). The server session
/// lives 10 minutes; [giveUpAfter] stops a little earlier.
@injectable
class TelegramWaitCubit extends Cubit<TelegramWaitState> {
  TelegramWaitCubit(this._claim) : super(const TelegramWaitState());

  static const every = Duration(seconds: 2);
  static const giveUpAfter = Duration(minutes: 9);

  final ClaimTelegramLogin _claim;
  late TelegramLogin _login;
  Timer? _poll, _deadline;
  bool _busy = false;

  void start(TelegramLogin login) {
    _login = login;
    _poll = Timer.periodic(every, (_) => check());
    _deadline = Timer(giveUpAfter, () => _finish(state.copyWith(status: TelegramWaitStatus.expired)));
  }

  Future<void> check() async {
    if (_busy || state.status != TelegramWaitStatus.waiting) return;
    _busy = true;
    final r = await _claim(_login);
    _busy = false;
    if (isClosed || state.status != TelegramWaitStatus.waiting) return;
    r.match(
      (f) {
        switch (f) {
          case NetworkFailure():
            emit(state.copyWith(offline: true));
          case NotFoundFailure():
            _finish(state.copyWith(status: TelegramWaitStatus.expired, offline: false));
          default:
            // May pass; keep asking, but leave the cause in the log.
            debugPrint('Telegram claim failed: ${f.message}');
        }
      },
      (result) => result == null
          ? emit(state.copyWith(offline: false))
          : _finish(state.copyWith(status: TelegramWaitStatus.verified, needsProfile: result.needsProfile, offline: false)),
    );
  }

  void _finish(TelegramWaitState s) {
    _poll?.cancel();
    _deadline?.cancel();
    emit(s);
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    _deadline?.cancel();
    return super.close();
  }
}
