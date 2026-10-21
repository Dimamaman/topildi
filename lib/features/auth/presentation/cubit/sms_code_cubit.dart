import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/usecases/request_sms_code.dart';
import '../../domain/usecases/verify_sms_code.dart';
import '../../../../core/l10n/tr.dart';

class SmsCodeState extends Equatable {
  const SmsCodeState({this.code = '', this.seconds = SmsCodeCubit.resendAfter, this.verifying = false, this.error, this.verified = false});

  final String code;
  final int seconds;
  final bool verifying, verified;
  final String? error;

  SmsCodeState copyWith({String? code, int? seconds, bool? verifying, String? Function()? error, bool? verified}) => SmsCodeState(
        code: code ?? this.code,
        seconds: seconds ?? this.seconds,
        verifying: verifying ?? this.verifying,
        error: error != null ? error() : this.error,
        verified: verified ?? this.verified,
      );

  @override
  List<Object?> get props => [code, seconds, verifying, error, verified];
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
    emit(state.copyWith(code: v, error: () => null));
    if (v.length == VerifySmsCode.codeLength) verify();
  }

  Future<void> verify() async {
    if (state.verifying) return;
    emit(state.copyWith(verifying: true, error: () => null));
    final r = await _verify((phone: _phone, code: state.code));
    if (isClosed) return;
    r.match(
      (f) => emit(state.copyWith(
        verifying: false,
        error: () => switch (f) {
          NetworkFailure() => tr('Internet yoʻq. Qayta urinib koʻring'),
          ValidationFailure(:final message) => message,
          _ => tr('Kodni tekshirib boʻlmadi'),
        },
      )),
      (_) => emit(state.copyWith(verifying: false, verified: true)),
    );
  }

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
