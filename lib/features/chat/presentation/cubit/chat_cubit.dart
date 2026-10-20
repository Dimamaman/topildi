import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/view_state.dart';
import '../../domain/entities/chat.dart';
import '../../domain/usecases/get_chat_thread.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/mark_returned.dart';
import '../../domain/usecases/send_message.dart';

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
  ChatCubit(this._getThread, this._getMessages, this._send, this._markReturned) : super(const ChatState());

  final GetChatThread _getThread;
  final GetMessages _getMessages;
  final SendMessage _send;
  final MarkReturned _markReturned;
  late String _chatId;

  ChatData? get _data => switch (state.view) {
        ViewLoaded(:final data) => data,
        _ => null,
      };

  Future<void> load(String chatId) async {
    _chatId = chatId;
    emit(state.copyWith(view: const ViewLoading()));
    final thread = await _getThread(chatId);
    final messages = await _getMessages(chatId);
    if (isClosed) return;
    final combined = thread.flatMap((t) => messages.map((m) => ChatData(thread: t, messages: m)));
    emit(state.copyWith(view: combined.fold<ViewState<ChatData>>((f) => ViewError(f), ViewLoaded.new)));
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
        emit(state.copyWith(view: ViewLoaded(data.copyWith(messages: [...data.messages, m]))));
        return true;
      },
    );
  }

  Future<void> markReturned() async {
    if (state.returning) return;
    emit(state.copyWith(returning: true));
    final result = await _markReturned(_chatId);
    if (isClosed) return;
    await result.match(
      (f) async => emit(state.copyWith(returning: false, failure: f)),
      (summary) async {
        final thread = await _getThread(_chatId);
        final messages = await _getMessages(_chatId);
        if (isClosed) return;
        final data = _data;
        emit(state.copyWith(
          returning: false,
          returnedSummary: summary,
          view: data == null
              ? null
              : ViewLoaded(data.copyWith(
                  thread: thread.getOrElse((_) => data.thread),
                  messages: messages.getOrElse((_) => data.messages),
                )),
        ));
      },
    );
  }
}
