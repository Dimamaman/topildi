import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_avatar.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/chat.dart';
import '../cubit/chat_cubit.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatCubit>()..load(chatId),
      child: _ChatView(chatId: chatId),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (a, b) => b.returnedSummary != null || (b.failure != null && a.failure != b.failure),
      listener: (context, state) {
        if (state.returnedSummary != null) {
          context.push(Routes.success(chatId));
        } else if (state.failure != null) {
          TFeedback.error(context, 'Amalni bajarib boʻlmadi. Qayta urinib koʻring');
        }
      },
      builder: (context, state) {
        final view = state.view;
        return Scaffold(
          body: switch (view) {
            ViewLoading() || ViewEmpty() => const Center(child: CircularProgressIndicator()),
            ViewError(:final isOffline) => SafeArea(
                child: isOffline ? OfflineState(onRetry: () => cubit.load(chatId)) : ErrorState(onRetry: () => cubit.load(chatId)),
              ),
            ViewLoaded(:final data) => Column(
                children: [
                  _Header(thread: data.thread, returning: state.returning),
                  Expanded(child: _Messages(messages: data.messages)),
                  if (!data.thread.returned) const _Composer() else const _ClosedNote(),
                ],
              ),
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.thread, required this.returning});

  final ChatThread thread;
  final bool returning;

  Future<void> _confirmReturned(BuildContext context) async {
    final ok = await TFeedback.confirm(
      context,
      title: 'Buyum qaytarildimi?',
      body: 'Buyumni egasiga topshirganingizni tasdiqlang. Eʼlon yopiladi.',
      confirmLabel: 'Ha, qaytarildi',
      cancelLabel: 'Hali emas',
    );
    if (ok && context.mounted) context.read<ChatCubit>().markReturned();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final other = thread.other;
    return Material(
      color: cs.surfaceContainerLowest,
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant))),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Orqaga',
                      icon: const Icon(Symbols.arrow_back_rounded),
                      onPressed: () => context.canPop() ? context.pop() : context.go(Routes.chats),
                    ),
                    const SizedBox(width: TSpace.xs),
                    TAvatar(
                      initials: TAvatar.initialsOf(other.displayName),
                      tone: thread.iAmFinder ? AvatarTone.lost : AvatarTone.primary,
                    ),
                    const SizedBox(width: TSpace.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(other.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Icon(Symbols.verified_rounded, size: 14, color: tc.success, fill: 1),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  thread.iAmFinder ? 'Egaligi tasdiqlangan' : 'Topuvchi',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tc.success),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Koʻproq',
                      icon: const Icon(Symbols.more_vert_rounded),
                      onSelected: (v) async {
                        if (v == 'report') {
                          final ok = await TFeedback.confirm(
                            context,
                            title: 'Shikoyat qilasizmi?',
                            body: 'Moderatorlar suhbatni koʻrib chiqadi.',
                            confirmLabel: 'Shikoyat qilish',
                            destructive: true,
                          );
                          if (ok && context.mounted) TFeedback.success(context, 'Shikoyat yuborildi');
                        }
                      },
                      itemBuilder: (_) => const [PopupMenuItem(value: 'report', child: Text('Shikoyat qilish'))],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(TSpace.xs),
                decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(TRadius.md)),
                child: Row(
                  children: [
                    PhotoPlaceholder(
                      icon: thread.listingCategory.icon,
                      tint: thread.listingTint,
                      width: 44,
                      height: 44,
                      iconSize: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thread.listingTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            thread.returned ? 'Egasiga qaytarilgan' : 'Soʻrov qabul qilingan',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (thread.iAmFinder && !thread.returned)
                      FilledButton.icon(
                        onPressed: returning ? null : () => _confirmReturned(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: tc.success,
                          foregroundColor: cs.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        icon: returning
                            ? SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.surface))
                            : const Icon(Symbols.check_rounded, size: 18),
                        label: const Text('Qaytarildi'),
                      )
                    else if (thread.returned)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Symbols.check_circle_rounded, color: tc.success, fill: 1),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Messages extends StatelessWidget {
  const _Messages({required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    // Reversed list keeps the newest message pinned to the bottom.
    final items = messages.reversed.toList();
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: TSpace.md, vertical: 14),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = items[i];
        return switch (m.kind) {
          MessageKind.text => _Bubble(message: m),
          _ => _SystemNote(message: m),
        };
      },
    );
  }
}

class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final safety = message.kind == MessageKind.safety;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: safety ? 320 : 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: safety ? cs.surfaceContainerHigh : tc.successContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (safety) ...[
                Icon(Symbols.shield_rounded, size: 16, color: cs.secondary),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  message.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: safety ? 12 : 13,
                    height: safety ? 17 / 12 : 18 / 13,
                    fontWeight: safety ? FontWeight.w400 : FontWeight.w500,
                    color: safety ? cs.secondary : tc.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = message.fromMe;
    final fg = me ? cs.onPrimary : cs.onSurface;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: me ? cs.primary : cs.surfaceContainerLowest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(me ? 16 : 4),
              bottomRight: Radius.circular(me ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: Text(message.text, style: TextStyle(fontSize: 15, height: 21 / 15, color: fg)),
              ),
              const SizedBox(height: 4),
              Text(TDate.time(message.sentAt), style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.75))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer();

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    final ok = await context.read<ChatCubit>().send(text);
    if (!ok && mounted) _controller.text = text;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Joylashuv yuborish',
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHigh,
                  fixedSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TRadius.md)),
                ),
                onPressed: () => _controller.text = 'Taxminiy uchrashuv joyi: metro kirish joyi',
                icon: const Icon(Symbols.location_on_rounded),
              ),
              const SizedBox(width: TSpace.xs),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Xabar yozing…',
                    fillColor: cs.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TSpace.xs),
              IconButton.filled(
                tooltip: 'Yuborish',
                style: IconButton.styleFrom(fixedSize: const Size(48, 48)),
                onPressed: _send,
                icon: const Icon(Symbols.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClosedNote extends StatelessWidget {
  const _ClosedNote();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(TSpace.md),
          child: Text(
            'Buyum egasiga qaytarildi. Chat yopilgan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
