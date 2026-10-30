import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/view_state.dart';
import '../../../block/domain/usecases/get_block_state.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/domain/usecases/get_listing_detail.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/mark_chat_read.dart';
import '../../domain/usecases/mark_returned.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/watch_chat.dart';

class ChatData extends Equatable {
  const ChatData({required this.thread, required this.messages});

  final ChatThread thread;
  final List<ChatMessage> messages;

  ChatData copyWith({ChatThread? thread, List<ChatMessage>? messages}) =>
      ChatData(thread: thread ?? this.thread, messages: messages ?? this.messages);

  @override
  List<Object?> get props => [thread, messages];
}

class ChatState extends Equatable {
  const ChatState({
    this.view = const ViewLoading(),
    this.listing,
    this.returning = false,
    this.returnedSummary,
    this.failure,
    this.blockedByMe = false,
    this.blockedMe = false,
  });

  final ViewState<ChatData> view;

  /// The chat's listing (district, date, photo for the item card); null
  /// until loaded or when it could not be read.
  final Listing? listing;
  final bool returning;

  /// Set once "Qaytarildi" succeeds, so the page can open Success.
  final ReturnSummary? returnedSummary;
  final Failure? failure;

  /// The signed-in user blocked the other member: writing is closed and the
  /// bar offers "Blokdan chiqarish".
  final bool blockedByMe;

  /// The other member blocked them: writing is closed with no way back, and
  /// the bar never says who blocked whom.
  final bool blockedMe;

  bool get canWrite => !blockedByMe && !blockedMe;

  ChatState copyWith({
    ViewState<ChatData>? view,
    Listing? listing,
    bool? returning,
    ReturnSummary? returnedSummary,
    Failure? failure,
    bool? blockedByMe,
    bool? blockedMe,
  }) => ChatState(
    view: view ?? this.view,
    listing: listing ?? this.listing,
    returning: returning ?? this.returning,
    returnedSummary: returnedSummary,
    failure: failure,
    blockedByMe: blockedByMe ?? this.blockedByMe,
    blockedMe: blockedMe ?? this.blockedMe,
  );

  @override
  List<Object?> get props => [view, listing, returning, returnedSummary, failure, blockedByMe, blockedMe];
}

@injectable
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._watch, this._markRead, this._send, this._markReturned, this._listing, this._blockState)
    : super(const ChatState());

  final WatchChat _watch;
  final MarkChatRead _markRead;
  final SendMessage _send;
  final MarkReturned _markReturned;
  final GetListingDetail _listing;
  final GetBlockState _blockState;
  late String _chatId;
  final _subs = <StreamSubscription<void>>[];
  ChatThread? _thread;
  List<ChatMessage>? _messages;

  /// Last incoming message already reported as read.
  String? _readUpTo;

  ChatData? get _data => switch (state.view) {
    ViewLoaded(:final data) => data,
    _ => null,
  };

  @override
  Future<void> close() async {
    await _cancel();
    return super.close();
  }

  Future<void> _cancel() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  /// Subscribes to the chat; also the retry after an error.
  Future<void> load(String chatId) async {
    _chatId = chatId;
    await _cancel();
    _thread = null;
    _messages = null;
    _readUpTo = null;
    emit(state.copyWith(view: const ViewLoading()));
    _subs
      ..add(
        _watch
            .thread(chatId)
            .listen(
              (r) => r.match(_fail, (t) {
                if (_thread == null) {
                  _loadListing(t.listingId);
                  refreshBlock(t.other.id);
                }
                _thread = t;
                _publish();
              }),
            ),
      )
      ..add(
        _watch
            .messages(chatId)
            .listen(
              (r) => r.match(_fail, (m) {
                _messages = m;
                _publish();
                _reportRead(m);
              }),
            ),
      );
  }

  void _fail(Failure f) {
    if (isClosed) return;
    _cancel();
    emit(state.copyWith(view: ViewError(f)));
  }

  void _publish() {
    final t = _thread, m = _messages;
    if (isClosed || t == null || m == null) return;
    emit(
      state.copyWith(
        view: ViewLoaded(ChatData(thread: t, messages: m)),
      ),
    );
  }

  Future<void> _loadListing(String id) async {
    if (state.listing != null) return;
    final result = await _listing(id);
    if (isClosed) return;
    // The card falls back to title and icon without it.
    result.match((_) {}, (l) => emit(state.copyWith(listing: l)));
  }

  /// Who has blocked whom, for the bottom bar. Asked when the chat opens
  /// and again after blocking or unblocking from the menu.
  Future<void> refreshBlock([String? otherId]) async {
    final uid = otherId ?? _thread?.other.id;
    if (uid == null || uid.isEmpty) return;
    final result = await _blockState(uid);
    if (isClosed) return;
    // A state we could not read leaves the chat as it is.
    result.match((_) {}, (s) => emit(state.copyWith(blockedByMe: s.byMe, blockedMe: s.ofMe)));
  }

  /// Marks the chat read when it opens and whenever a new message arrives.
  void _reportRead(List<ChatMessage> messages) {
    final incoming = messages.where((m) => !m.fromMe && !m.isSystem);
    final last = incoming.isEmpty ? '' : incoming.last.id;
    if (last == _readUpTo) return;
    _readUpTo = last;
    _markRead(_chatId);
  }

  /// Returns false when the message was not sent.
  Future<bool> send(String text) async {
    final data = _data;
    if (data == null || text.trim().isEmpty) return false;
    final result = await _send((chatId: _chatId, text: text));
    if (isClosed) return false;
    return result.match(
      (f) {
        emit(state.copyWith(failure: f));
        return false;
      },
      (m) {
        // Usually the live stream has it already.
        final current = _messages ?? data.messages;
        if (!current.any((e) => e.id == m.id)) {
          _messages = [...current, m];
          _publish();
        }
        return true;
      },
    );
  }

  Future<void> markReturned() async {
    if (state.returning) return;
    emit(state.copyWith(returning: true));
    final result = await _markReturned(_chatId);
    if (isClosed) return;
    result.match(
      (f) => emit(state.copyWith(returning: false, failure: f)),
      (summary) => emit(state.copyWith(returning: false, returnedSummary: summary)),
    );
  }
}
