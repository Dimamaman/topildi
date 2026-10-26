import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/watch_pending_claims.dart';

/// Pending claims per listing of the signed-in user, kept live for the
/// Profil tab badge. Errors keep the last known counts.
@injectable
class PendingClaimsCubit extends Cubit<Map<String, int>> {
  PendingClaimsCubit(WatchPendingClaims watch) : super(const {}) {
    _sub = watch().listen((r) {
      if (!isClosed) r.match((_) {}, emit);
    });
  }

  late final StreamSubscription<void> _sub;

  int get total => state.values.fold(0, (sum, n) => sum + n);

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
