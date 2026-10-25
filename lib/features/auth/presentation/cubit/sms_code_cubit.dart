import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/usecases/request_sms_code.dart';
import '../../domain/usecases/verify_sms_code.dart';
import '../../../../core/l10n/tr.dart';

class SmsCodeState extends Equatable {
  const SmsCodeState({
    this.code = '',
    this.seconds = SmsCodeCubit.resendAfter,
    this.verifying = false,
    this.error,
    this.verified = false,
    this.needsProfile = true,
    this.offline = false,
  });

  final String code;
  final int seconds;
  final bool verifying, verified;

  /// After [verified]: new users fill in the profile, returning ones go home.
  final bool needsProfile;
  final String? error;

  /// The last check failed for lack of network (shown as a banner, not as a wrong code).
  final bool offline;

  SmsCodeState copyWith({
    String? code,
    int? seconds,
    bool? verifying,
    String? Function()? error,
    bool? verified,
    bool? needsProfile,
    bool? offline,
  }) => SmsCodeState(
        code: code ?? this.code,
        seconds: seconds ?? this.seconds,
        verifying: verifying ?? this.verifying,
        error: error != null ? error() : this.error,
        verified: verified ?? this.verified,
        needsProfile: needsProfile ?? this.needsProfile,
        offline: offline ?? this.offline,
      );

  @override
  List<Object?> get props => [code, seconds, verifying, error, verified, needsProfile, offline];
}

@injectable
class SmsCodeCubit extends Cubit<SmsCodeState> {
  SmsCodeCubit(this._verify, this._request) : super(const SmsCodeState());

  static const resendAfter = 45;

  final VerifySmsCode _verify;
  final RequestSmsCode _request;
  late PhoneNumber _phone;
  Timer? _timer;

  void start(PhoneNumber phone) {
    _phone = phone;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    emit(state.copyWith(seconds: resendAfter));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.seconds <= 1) t.cancel();
      emit(state.copyWith(seconds: state.seconds - 1));
    });
  }

  /// Auto-submits once all 6 digits are in.
  void setCode(String v) {
    emit(state.copyWith(code: v, error: () => null, offline: false));
    if (v.length == VerifySmsCode.codeLength) verify();
  }

  Future<void> verify() async {
    if (state.verifying) return;
    emit(state.copyWith(verifying: true, error: () => null, offline: false));
    final r = await _verify((phone: _phone, code: state.code));
    if (isClosed) return;
    r.match(
      (f) => emit(state.copyWith(
        verifying: false,
        offline: f is NetworkFailure,
        error: () => switch (f) {
          NetworkFailure() => tr('Internet yoʻq. Qayta urinib koʻring'),
          ValidationFailure(:final message) => message,
          // Debug builds also show the cause (e.g. a Firestore rules refusal).
          _ when kDebugMode && f.message != null => '${tr('Kodni tekshirib boʻlmadi')}\n${f.message}',
          _ => tr('Kodni tekshirib boʻlmadi'),
        },
      )),
      (r) => emit(state.copyWith(verifying: false, verified: true, needsProfile: r.needsProfile)),
    );
  }

  /// Empties the cells after a wrong code; the error message stays until the next digit.
  void clearCode() => emit(state.copyWith(code: ''));

  Future<void> resend() async {
    if (state.seconds > 0) return;
    _startTimer();
    await _request(_phone);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
