import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/view_state.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_usecases.dart';

@injectable
class NotificationsCubit extends Cubit<ViewState<List<AppNotification>>> {
  NotificationsCubit(this._get, this._markAll, this._markOne) : super(const ViewLoading());

  final GetNotifications _get;
  final MarkAllNotificationsRead _markAll;
  final MarkNotificationRead _markOne;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(const ViewLoading());
    final r = await _get(const NoParams());
    if (isClosed) return;
    emit(r.fold<ViewState<List<AppNotification>>>(
      (f) => ViewError(f),
      (l) => l.isEmpty ? const ViewEmpty() : ViewLoaded(l),
    ));
  }

  Future<void> markAllRead() async {
    await _markAll(const NoParams());
    await load(silent: true);
  }

  Future<void> open(AppNotification n) async {
    if (n.read) return;
    await _markOne(n.id);
    await load(silent: true);
  }
}

/// Unread count for the bell on the feed.
@injectable
class NotificationBadgeCubit extends Cubit<int> {
  NotificationBadgeCubit(WatchUnreadNotifications watch) : super(0) {
    _sub = watch().listen(emit);
  }

  late final StreamSubscription<int> _sub;

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
