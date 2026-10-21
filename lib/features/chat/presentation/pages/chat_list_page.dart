import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/glass_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_avatar.dart';
import '../../../../core/widgets/t_refresh_scroll_view.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/chat.dart';
import '../cubit/chat_list_cubit.dart';
import '../../../../core/l10n/tr.dart';

const _title = 'Chatlar';
const _side = GlassHeader.side;

/// Pinned bar height under the status bar (inline title only, no buttons).
const _barHeight = 30.0;

/// Large title: 0 above (the bar gives the 30), 41 line, 12 below.
const _titleExtent = GlassHeader.titleLine + 12;

/// Chats tab, iOS 26 style: large "Chatlar" title that collapses into a
/// glass bar, chats in one white inset group, privacy note underneath.
/// The [ChatListCubit] is provided by the app shell (it also feeds the
/// unread badge on the tab bar).
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _offset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<ChatListCubit>();
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.depth == 0 && n.metrics.axis == Axis.vertical) _offset.value = n.metrics.pixels;
            return false;
          },
          child: BlocBuilder<ChatListCubit, ViewState<List<ChatThread>>>(
            builder: (context, state) => TRefreshScrollView(
              onRefresh: () => cubit.load(silent: true),
              edgeOffset: top + _barHeight,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _Bar(top: top, offset: _offset),
                ),
                SliverToBoxAdapter(
                  child: GlassLargeTitle(tr(_title), padding: EdgeInsets.fromLTRB(_side + 4, 0, _side + 4, 12)),
                ),
                ..._body(context, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, ViewState<List<ChatThread>> state) {
    final cubit = context.read<ChatListCubit>();
    // The shell's floating tab bar height arrives as bottom padding.
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    Widget padded(Widget child) => SliverPadding(
      padding: EdgeInsets.fromLTRB(_side, 6, _side, bottom),
      sliver: SliverToBoxAdapter(child: child),
    );
    return switch (state) {
      ViewLoading() => [
        padded(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_Group(children: [_RowSkeleton(), _RowSkeleton(), _RowSkeleton()]), _PrivacyNote()],
          ),
        ),
      ],
      ViewEmpty() => [
        padded(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmptyState(
                icon: Symbols.chat_bubble_rounded,
                title: tr('Hali chat yoʻq'),
                body: tr('Soʻrovingiz qabul qilinsa yoki siz soʻrovni qabul qilsangiz, chat shu yerda paydo boʻladi.'),
              ),
              _PrivacyNote(),
            ],
          ),
        ),
      ],
      ViewError(:final isOffline) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load),
          ),
        ),
      ],
      ViewLoaded(:final data) => [
        padded(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Group(
                children: [
                  for (var i = 0; i < data.length; i++) _ChatRow(thread: data[i], divider: i < data.length - 1),
                ],
              ),
              const _PrivacyNote(),
            ],
          ),
        ),
      ],
    };
  }
}

/// Pinned glass strip under the status bar; the inline title fades in.
class _Bar extends SliverPersistentHeaderDelegate {
  const _Bar({required this.top, required this.offset});

  final double top;
  final ValueListenable<double> offset;

  @override
  double get minExtent => top + _barHeight;

  @override
  double get maxExtent => top + _barHeight;

  @override
  bool shouldRebuild(covariant _Bar old) => old.top != top || old.offset != offset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return GlassBarBackground(
      offset: offset,
      hairlineAt: _titleExtent - 1,
      child: Padding(
        padding: EdgeInsets.only(top: top, left: _side, right: _side),
        child: Center(
          child: ValueListenableBuilder<double>(
            valueListenable: offset,
            // Fades in as the large title passes under the bar.
            builder: (context, o, child) =>
                Opacity(opacity: ((o - GlassHeader.titleLine * 0.6) / 16).clamp(0.0, 1.0), child: child),
            child: ExcludeSemantics(
              child: Text(
                tr(_title),
                maxLines: 1,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontSize: 17, height: 22 / 17).inter(FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White inset group (radius 26).
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(children: children),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.thread, required this.divider});

  final ChatThread thread;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final ts = context.ts;
    final text = Theme.of(context).textTheme;
    final unread = thread.unread > 0;
    final time = TDate.chat(thread.lastAt);
    final name = thread.other.displayName;
    final meta = text.bodySmall!.copyWith(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant);

    return Semantics(
      button: true,
      label: [
        if (unread) tr('Oʻqilmagan'),
        name,
        thread.listingTitle,
        if (thread.returned) tr('Qaytarildi'),
        thread.lastMessage,
        time,
      ].join('. '),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.push(Routes.chat(thread.id)),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              // Unread dot; the space stays when read so rows line up.
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: unread ? cs.primary : Colors.transparent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: unread ? cs.primaryContainer : cs.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        TAvatar.initialsOf(name),
                        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
                        style: text.titleMedium!
                            .copyWith(
                              fontSize: 17,
                              height: 22 / 17,
                              color: unread ? cs.onPrimaryContainer : cs.secondary,
                            )
                            .inter(FontWeight.w600),
                      ),
                    ),
                    // The item: category tint + icon, framed in the group colour.
                    Positioned(
                      right: -5,
                      bottom: -5,
                      child: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ts.placeholder(thread.listingTint),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cs.surfaceContainerLowest, width: 2),
                        ),
                        child: Icon(thread.listingCategory.icon, size: 15, color: ts.placeholderIcon),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
                  decoration: divider
                      ? BoxDecoration(
                          border: Border(bottom: BorderSide(color: ts.separator, width: 0.5)),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium!
                                  .copyWith(fontSize: 16, height: 21 / 16, color: cs.onSurface)
                                  .inter(unread ? FontWeight.w700 : FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: unread
                                ? text.bodyMedium!
                                      .copyWith(fontSize: 14, height: 19 / 14, color: cs.primary)
                                      .inter(FontWeight.w600)
                                : text.bodyMedium!.copyWith(
                                    fontSize: 14,
                                    height: 19 / 14,
                                    color: cs.onSurfaceVariant,
                                  ),
                          ),
                        ],
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: thread.listingTitle),
                            if (thread.returned) ...[
                              const TextSpan(text: ' · '),
                              TextSpan(
                                text: tr('Qaytarildi'),
                                style: meta.copyWith(color: tc.success).inter(FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: meta,
                      ),
                      Text(
                        thread.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: unread
                            ? text.bodyLarge!
                                  .copyWith(fontSize: 15, height: 20 / 15, color: cs.onSurface)
                                  .inter(FontWeight.w600)
                            : text.bodyLarge!.copyWith(fontSize: 15, height: 20 / 15, color: cs.onSurfaceVariant),
                      ),
                    ],
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

/// 🔒 Chat faqat soʻrov qabul qilingandan keyin ochiladi…
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Symbols.lock_rounded, size: 15, fill: 1, color: cs.primary),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tr('Chat faqat soʻrov qabul qilingandan keyin ochiladi. Telefon raqamlar yashirin.'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton matching [_ChatRow].
class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    Widget bar(double factor, double h, Color c) => FractionallySizedBox(
      widthFactor: factor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: h,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(TRadius.xs)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: ts.skeleton, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(0.45, 15, ts.skeleton),
                const SizedBox(height: 7),
                bar(0.6, 12, ts.skeletonSoft),
                const SizedBox(height: 7),
                bar(0.85, 13, ts.skeletonSoft),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
