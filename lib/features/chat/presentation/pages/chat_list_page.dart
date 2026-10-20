import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_avatar.dart';
import '../../../../core/widgets/t_refresh_scroll_view.dart';
import '../../domain/entities/chat.dart';
import '../cubit/chat_list_cubit.dart';

/// Chats tab. The [ChatListCubit] is provided by the app shell (it also
/// feeds the unread badge).
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<ChatListCubit>();
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: cs.surfaceContainerLowest,
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(TSpace.screen, TSpace.lg, TSpace.screen, TSpace.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chatlar', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: TSpace.sm),
                      Row(
                        children: [
                          Icon(Symbols.lock_rounded, size: 16, color: cs.onSurfaceVariant),
                          const SizedBox(width: TSpace.xs),
                          Expanded(
                            child: Text(
                              'Chat faqat soʻrov qabul qilingandan keyin ochiladi',
                              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ChatListCubit, ViewState<List<ChatThread>>>(
              builder: (context, state) => switch (state) {
                ViewLoading() => const RowsSkeleton(),
                ViewEmpty() => EmptyState(
                  icon: Symbols.chat_bubble_rounded,
                  title: 'Hali chatlar yoʻq',
                  body: 'Soʻrov qabul qilingach, topuvchi yoki egasi bilan shu yerda yozishasiz.',
                  cta: 'Lentani koʻrish',
                  onCta: () => context.go(Routes.home),
                ),
                ViewError(:final isOffline) =>
                  isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load),
                ViewLoaded(:final data) => TRefreshScrollView(
                  onRefresh: () => cubit.load(silent: true),
                  slivers: [
                    SliverList.builder(
                      itemCount: data.length,
                      itemBuilder: (context, i) => _ChatRow(thread: data[i]),
                    ),
                  ],
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = context.ts;
    final unread = thread.unread > 0;
    final tone = thread.returned ? AvatarTone.neutral : (thread.iAmFinder ? AvatarTone.lost : AvatarTone.primary);
    final now = DateTime.now();
    final sameDay = now.year == thread.lastAt.year && now.month == thread.lastAt.month && now.day == thread.lastAt.day;
    final time = sameDay ? TDate.time(thread.lastAt) : TDate.relative(thread.lastAt).split(',').first;

    return Material(
      color: unread ? ts.primaryTint : Colors.transparent,
      child: InkWell(
        onTap: () => context.push(Routes.chat(thread.id)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: TSpace.screen, vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TAvatar(initials: TAvatar.initialsOf(thread.other.displayName), size: 52, tone: tone),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: ts.placeholder(thread.listingTint),
                          borderRadius: BorderRadius.circular(TRadius.xs),
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.other.displayName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(time, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      thread.returned ? '${thread.listingTitle} · Qaytarildi' : thread.listingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: unread ? cs.onSurface : cs.onSurfaceVariant,
                              fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: TSpace.xs),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(11)),
                            child: Text(
                              '${thread.unread}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onPrimary),
                            ),
                          ),
                        ],
                      ],
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
