import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/view_state.dart';
import '../../domain/entities/blocked_user.dart';
import '../../domain/usecases/block_user.dart';
import '../../domain/usecases/unblock_user.dart';
import '../../domain/usecases/watch_blocked.dart';

class BlockedState extends Equatable {
  const BlockedState({this.view = const ViewLoading(), this.failure});

  final ViewState<List<BlockedUser>> view;

  /// Set once when an unblock fails; the page shows it and moves on.
  final Failure? failure;

  List<BlockedUser> get people => switch (view) {
    ViewLoaded(:final data) => data,
    _ => const [],
  };

  BlockedState copyWith({ViewState<List<BlockedUser>>? view, Failure? failure}) =>
      BlockedState(view: view ?? this.view, failure: failure);

  @override
  List<Object?> get props => [view, failure];
}

/// "Bloklanganlar": the list, live, with unblocking and the undo behind the
/// snackbar's "Bekor qilish".
@injectable
class BlockedCubit extends Cubit<BlockedState> {
  BlockedCubit(this._watch, this._unblock, this._block) : super(const BlockedState());

  final WatchBlocked _watch;
  final UnblockUser _unblock;
  final BlockUser _block;
  StreamSubscription<void>? _sub;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  Future<void> load() async {
    await _sub?.cancel();
    emit(const BlockedState());
    _sub = _watch().listen(
      (r) => r.match(
        (f) => emit(state.copyWith(view: ViewError(f))),
        (list) => emit(state.copyWith(view: list.isEmpty ? const ViewEmpty() : ViewLoaded(list))),
      ),
    );
  }

  /// Returns false when nothing changed, so the page keeps the row.
  Future<bool> unblock(String uid) async {
    final result = await _unblock(uid);
    if (isClosed) return false;
    return result.match((f) {
      emit(state.copyWith(failure: f));
      return false;
    }, (_) => true);
  }

  /// "Bekor qilish" on the snackbar: puts them back on the list.
  Future<void> undo(BlockedUser person) async {
    final result = await _block((uid: person.id, name: person.name));
    if (isClosed) return;
    result.match((f) => emit(state.copyWith(failure: f)), (_) {});
  }
}
