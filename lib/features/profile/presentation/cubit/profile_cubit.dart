import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/view_state.dart';
import '../../../claim/domain/usecases/watch_pending_claims.dart';
import '../../../listing/domain/usecases/watch_listings.dart';
import '../../domain/entities/profile_summary.dart';
import '../../domain/usecases/profile_usecases.dart';

class ProfileState extends Equatable {
  const ProfileState({this.view = const ViewLoading(), this.showReturned = false, this.signedOut = false});

  final ViewState<ProfileSummary> view;
  final bool showReturned, signedOut;

  ProfileState copyWith({ViewState<ProfileSummary>? view, bool? showReturned, bool? signedOut}) => ProfileState(
        view: view ?? this.view,
        showReturned: showReturned ?? this.showReturned,
        signedOut: signedOut ?? this.signedOut,
      );

  @override
  List<Object?> get props => [view, showReturned, signedOut];
}

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._get, this._setNotifications, this._signOut, WatchListings watch, WatchPendingClaims pending)
      : super(const ProfileState()) {
    _sub = watch().listen((_) => load(silent: true));
    // A claim arrived or was answered: refresh the "Soʻrov bor" tags.
    _pendingSub = pending().listen((r) => r.match((_) {}, (counts) {
          final changed = _pending != null && !mapEquals(_pending, counts);
          _pending = counts;
          if (changed) load(silent: true);
        }));
  }

  final GetMyProfile _get;
  final SetNotifications _setNotifications;
  final SignOut _signOut;
  late final StreamSubscription<void> _sub;
  late final StreamSubscription<void> _pendingSub;
  Map<String, int>? _pending;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(view: const ViewLoading()));
    final r = await _get(const NoParams());
    if (isClosed) return;
    emit(state.copyWith(view: r.fold<ViewState<ProfileSummary>>((f) => ViewError(f), ViewLoaded.new)));
  }

  void showTab({required bool returned}) => emit(state.copyWith(showReturned: returned));

  Future<void> setNotifications(bool on) async {
    await _setNotifications(on);
    await load(silent: true);
  }

  Future<void> signOut() async {
    await _signOut(const NoParams());
    if (!isClosed) emit(state.copyWith(signedOut: true));
  }

  @override
  Future<void> close() {
    _sub.cancel();
    _pendingSub.cancel();
    return super.close();
  }
}
