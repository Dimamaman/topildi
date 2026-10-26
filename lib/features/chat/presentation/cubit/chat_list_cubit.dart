import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/view_state.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/watch_chats.dart';

@injectable
class ChatListCubit extends Cubit<ViewState<List<ChatThread>>> {
  ChatListCubit(this._watch) : super(const ViewLoading());

  final WatchChats _watch;
  StreamSubscription<void>? _sub;

  /// Unread messages across all chats, for the nav badge.
  int get unread => switch (state) {
        ViewLoaded(:final data) => data.fold(0, (sum, t) => sum + t.unread),
        _ => 0,
      };

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }

  /// (Re)subscribes to the live chat list; also the retry after an error.
  Future<void> load({bool silent = false}) async {
    await _sub?.cancel();
    if (!silent) emit(const ViewLoading());
    _sub = _watch().listen((result) {
      if (isClosed) return;
      emit(result.fold<ViewState<List<ChatThread>>>(
        (f) => ViewError(f),
        (list) => list.isEmpty ? const ViewEmpty() : ViewLoaded(list),
      ));
    });
  }
}
