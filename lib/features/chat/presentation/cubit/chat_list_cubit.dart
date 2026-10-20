import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/view_state.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/get_chats.dart';
import '../../domain/usecases/watch_chats.dart';

@injectable
class ChatListCubit extends Cubit<ViewState<List<ChatThread>>> {
  ChatListCubit(this._getChats, WatchChats watch) : super(const ViewLoading()) {
    _sub = watch().listen((_) => load(silent: true));
  }

  final GetChats _getChats;
  late final StreamSubscription<void> _sub;

  /// Unread messages across all chats, for the nav badge.
  int get unread => switch (state) {
        ViewLoaded(:final data) => data.fold(0, (sum, t) => sum + t.unread),
        _ => 0,
      };

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const ViewLoading());
    final result = await _getChats(const NoParams());
    if (isClosed) return;
    emit(result.fold<ViewState<List<ChatThread>>>(
      (f) => ViewError(f),
      (list) => list.isEmpty ? const ViewEmpty() : ViewLoaded(list),
    ));
  }
}
