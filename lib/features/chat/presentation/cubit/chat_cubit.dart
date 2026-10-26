import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/view_state.dart';
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
  const ChatState({this.view = const ViewLoading(), this.returning = false, this.returnedSummary, this.failure});

  final ViewState<ChatData> view;
  final bool returning;

  /// Set once "Qaytarildi" succeeds, so the page can open Success.
  final ReturnSummary? returnedSummary;
  final Failure? failure;

  ChatState copyWith({ViewState<ChatData>? view, bool? returning, ReturnSummary? returnedSummary, Failure? failure}) =>
      ChatState(
        view: view ?? this.view,
        returning: returning ?? this.returning,
        returnedSummary: returnedSummary,
        failure: failure,
      );

  @override
  List<Object?> get props => [view, returning, returnedSummary, failure];
}

@injectable
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._watch, this._markRead, this._send, this._markReturned) : super(const ChatState());

  final WatchChat _watch;
  final MarkChatRead _markRead;
  final SendMessage _send;
  final MarkReturned _markReturned;
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
      ..add(_watch.thread(chatId).listen((r) => r.match(_fail, (t) {
            _thread = t;
            _publish();
          })))
      ..add(_watch.messages(chatId).listen((r) => r.match(_fail, (m) {
            _messages = m;
            _publish();
            _reportRead(m);
          })));
  }

  void _fail(Failure f) {
    if (isClosed) return;
    _cancel();
    emit(state.copyWith(view: ViewError(f)));
  }

  void _publish() {
    final t = _thread, m = _messages;
    if (isClosed || t == null || m == null) return;
    emit(state.copyWith(view: ViewLoaded(ChatData(thread: t, messages: m))));
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
