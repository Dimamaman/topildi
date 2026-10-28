import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/claim.dart';
import '../../domain/usecases/watch_claim.dart';

/// "Soʻrov yuborildi": follows the sent claim while the screen is open, so
/// it can turn into "Qabul qilindi!" or "mos kelmadi" in place. A failing
/// stream (offline, taken back) just leaves the last known status.
@injectable
class ClaimSentCubit extends Cubit<ClaimStatus> {
  ClaimSentCubit(this._watch) : super(ClaimStatus.pending);

  final WatchClaim _watch;
  StreamSubscription<Object?>? _sub;

  void watch(String claimId) {
    _sub?.cancel();
    _sub = _watch(claimId).listen((r) => r.match((_) {}, (claim) => emit(claim.status)));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
