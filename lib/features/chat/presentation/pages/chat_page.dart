import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/pull_down_menu.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/chat.dart';
import '../cubit/chat_cubit.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.chatId});

  final String chatId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _push = getIt<PushService>();

  @override
  void initState() {
    super.initState();
    _push.setChatOpen(true);
  }

  @override
  void dispose() {
    _push.setChatOpen(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatCubit>()..load(widget.chatId),
      child: _ChatView(chatId: widget.chatId),
    );
  }
}

/// Chat screen colours not covered by the colour scheme.
@immutable
class _ChatColors {
  const _ChatColors._({
    required this.glow,
    required this.glassHeader,
    required this.glassCard,
    required this.glassBar,
    required this.hint,
    required this.myTime,
    required this.otherTime,
  });

  /// Radial light at the top of the page.
  final Color glow;
  final Color glassHeader, glassCard, glassBar;

  /// Day labels, placeholder, lock icon.
  final Color hint;
  final Color myTime, otherTime;

  static const _light = _ChatColors._(
    glow: Color(0xFFE3EBFC),
    glassHeader: Color(0xCCFFFFFF),
    glassCard: Color(0xD1FFFFFF),
    glassBar: Color(0xD9FFFFFF),
    hint: Color(0xFF8A94A6),
    myTime: Color(0xBFFFFFFF),
    otherTime: Color(0xFF8A94A6),
  );

  static const _dark = _ChatColors._(
    glow: Color(0xFF182031),
    glassHeader: Color(0xD1182031),
    glassCard: Color(0xD1182031),
    glassBar: Color(0xD1182031),
    hint: Color(0xFF9AA6BB),
    myTime: Color(0xB30B2A6B),
    otherTime: Color(0xFF9AA6BB),
  );

  static _ChatColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

class _ChatView extends StatelessWidget {
  const _ChatView({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    final cs = Theme.of(context).colorScheme;
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (a, b) =>
          b.returnedSummary != null ||
          (b.failure != null && a.failure != b.failure) ||
          _returned(a) != _returned(b),
      listener: (context, state) {
        if (_returned(state)) FocusScope.of(context).unfocus();
        if (state.returnedSummary != null) {
          context.push(Routes.success(chatId));
        } else if (state.failure != null) {
          TFeedback.error(
            context,
            tr('Amalni bajarib boʻlmadi. Qayta urinib koʻring.'),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: cs.surface,
          body: switch (state.view) {
            ViewLoading() || ViewEmpty() => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            ViewError(:final isOffline) => SafeArea(
              child: isOffline
                  ? OfflineState(onRetry: () => cubit.load(chatId))
                  : ErrorState(onRetry: () => cubit.load(chatId)),
            ),
            ViewLoaded(:final data) => _Body(
              data: data,
              listing: state.listing,
              returning: state.returning,
            ),
          },
        );
      },
    );
  }

  static bool _returned(ChatState s) => switch (s.view) {
    ViewLoaded(:final data) => data.thread.returned,
    _ => false,
  };
}

class _Body extends StatefulWidget {
  const _Body({
    required this.data,
    required this.listing,
    required this.returning,
  });

  final ChatData data;
  final Listing? listing;
  final bool returning;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _barKey = GlobalKey();

  /// Height of the bottom bar, which grows with long input or large text;
  /// the list keeps its last message above it.
  double _barHeight = 48;

  void _measureBar() {
    final h = _barKey.currentContext?.size?.height;
    if (h != null && h != _barHeight && mounted) setState(() => _barHeight = h);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBar());
    final cs = Theme.of(context).colorScheme;
    final c = _ChatColors.of(context);
    final mq = MediaQuery.of(context);
    final thread = widget.data.thread;
    // Notched iPhones: 54 under a 59 inset, as in the design; elsewhere
    // just below the status bar.
    final top = mq.padding.top >= 44 ? mq.padding.top - 5 : mq.padding.top + 8;
    // The keyboard eats the bottom inset; then sit just above it.
    final bottom = mq.viewInsets.bottom > 0
        ? 8.0
        : math.max(30.0, mq.padding.bottom);
    final cardTop = top + 64;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                // CSS `circle at 50% 0` to 50%: half the distance to the
                // farthest corner, about 1.1 widths on a phone.
                radius: 1.1,
                colors: [c.glow, c.glow.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: _Messages(
            thread: thread,
            messages: widget.data.messages,
            padding: EdgeInsets.fromLTRB(
              16,
              cardTop + 78,
              16,
              bottom + _barHeight + 32,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: top + 58,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.7, 1],
                  colors: [cs.surface, cs.surface.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottom + _barHeight + 42,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.45],
                  colors: [cs.surface.withValues(alpha: 0), cs.surface],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: top,
          child: _Header(thread: thread, returning: widget.returning),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: cardTop,
          child: _ItemCard(thread: thread, listing: widget.listing),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: bottom,
          child: AnimatedSwitcher(
            key: _barKey,
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 8 / 56),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: thread.returned
                ? _ClosedBar(
                    key: const ValueKey('closed'),
                    listingId: thread.listingId,
                  )
                : const _Composer(key: ValueKey('composer')),
          ),
        ),
      ],
    );
  }
}

/// 44×44 glass circle.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 44,
          child: GlassSurface(
            color: _ChatColors.of(context).glassHeader,
            child: Center(child: Icon(icon, size: 24, color: cs.onSurface)),
          ),
        ),
      ),
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
      title: tr('Buyum qaytarildimi?'),
      body: tr('Buyumni egasiga topshirganingizni tasdiqlang. Eʼlon yopiladi.'),
      confirmLabel: tr('Ha, qaytarildi'),
      cancelLabel: tr('Hali emas'),
    );
    if (ok && context.mounted) context.read<ChatCubit>().markReturned();
  }

  Future<void> _report(BuildContext context) async {
    final ok = await TFeedback.confirm(
      context,
      title: tr('Shikoyat qilasizmi?'),
      body: tr('Moderatorlar suhbatni koʻrib chiqadi.'),
      confirmLabel: tr('Shikoyat qilish'),
      destructive: true,
    );
    if (ok && context.mounted) {
      TFeedback.success(context, tr('Shikoyat yuborildi'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final other = thread.other;
    final name = other.displayName.trim();
    // The finder hands the item over, so it can be marked returned only by them.
    final canReturn = thread.iAmFinder && !thread.returned && !returning;
    return Row(
      children: [
        _GlassIconButton(
          icon: Symbols.arrow_back_rounded,
          label: tr('Orqaga'),
          onTap: () =>
              context.canPop() ? context.pop() : context.go(Routes.chats),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 52,
            child: GlassSurface(
              color: _ChatColors.of(context).glassHeader,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            height: 20 / 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Symbols.verified_rounded,
                              size: 14,
                              fill: 1,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                thread.iAmFinder ? tr('Egasi') : tr('Topuvchi'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Builder(
          builder: (anchor) => _GlassIconButton(
            icon: Symbols.more_horiz_rounded,
            label: tr('Koʻproq'),
            onTap: () async {
              final v = await showPullDownMenu(
                context,
                anchor: anchor,
                label: tr('Koʻproq'),
                items: [
                  if (canReturn) ('returned', tr('Buyum qaytarildi')),
                  ('report', tr('Shikoyat qilish')),
                ],
                icons: {
                  if (canReturn) 0: Symbols.handshake_rounded,
                  canReturn ? 1 : 0: Symbols.flag_rounded,
                },
                destructive: {canReturn ? 1 : 0},
              );
              if (!context.mounted) return;
              if (v == 'returned') {
                await _confirmReturned(context);
              } else if (v == 'report') {
                await _report(context);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.thread, required this.listing});

  final ChatThread thread;
  final Listing? listing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = listing;
    final meta = l == null
        ? null
        : [
            if (l.district.isNotEmpty) tr(l.district),
            TDate.dayMonth(l.happenedAt),
          ].join(' · ');
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(Routes.listing(thread.listingId)),
        child: GlassSurface(
          radius: 22,
          color: _ChatColors.of(context).glassCard,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PhotoPlaceholder(
                icon: thread.listingCategory.icon,
                tint: thread.listingTint,
                path: l == null || l.photos.isEmpty ? null : l.photos.first,
                width: 48,
                height: 48,
                iconSize: 26,
                radius: 15,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.listingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (meta != null)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(returned: thread.returned),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.returned});

  final bool returned;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = returned ? cs.onPrimaryContainer : cs.secondary;
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: returned ? cs.primaryContainer : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: returned ? null : Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            returned ? Symbols.handshake_rounded : Symbols.forum_rounded,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            returned ? tr('Qaytarildi') : tr('Faol chat'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of the message list.
sealed class _Row {
  const _Row();
}

class _DayRow extends _Row {
  const _DayRow(this.day);

  final DateTime day;
}

class _NoteRow extends _Row {
  const _NoteRow(this.message);

  final ChatMessage message;
}

class _BubbleRow extends _Row {
  const _BubbleRow(this.message, {required this.tail});

  final ChatMessage message;

  /// Last of consecutive messages from the same person.
  final bool tail;
}

class _Messages extends StatelessWidget {
  const _Messages({
    required this.thread,
    required this.messages,
    required this.padding,
  });

  final ChatThread thread;
  final List<ChatMessage> messages;
  final EdgeInsets padding;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<_Row> _rows() {
    // The safety tip is no longer shown in the chat.
    final shown = messages.where((m) => m.kind != MessageKind.safety).toList();
    final rows = <_Row>[];
    for (var i = 0; i < shown.length; i++) {
      final m = shown[i];
      if (i == 0 || !_sameDay(shown[i - 1].sentAt, m.sentAt)) {
        rows.add(_DayRow(m.sentAt));
      }
      if (m.kind != MessageKind.text) {
        rows.add(_NoteRow(m));
        continue;
      }
      final next = i + 1 < shown.length ? shown[i + 1] : null;
      final tail =
          next == null ||
          next.kind != MessageKind.text ||
          next.fromMe != m.fromMe ||
          !_sameDay(next.sentAt, m.sentAt);
      rows.add(_BubbleRow(m, tail: tail));
    }
    return rows;
  }

  /// Space above [row] when [prev] is the row before it.
  static double _gap(_Row? prev, _Row row) {
    if (prev == null) return 0;
    if (prev is _DayRow) return 12;
    if (prev is _NoteRow || row is _NoteRow || row is _DayRow) return 12;
    return 8;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    // Reversed list keeps the newest message pinned to the bottom.
    return ListView.builder(
      reverse: true,
      padding: padding,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final index = rows.length - 1 - i;
        final row = rows[index];
        final child = switch (row) {
          _DayRow(:final day) => _DayLabel(day: day),
          _NoteRow(:final message) => _SystemNote(message: message),
          _BubbleRow(:final message, :final tail) => _Bubble(
            message: message,
            tail: tail,
            seen: thread.seen(message),
          ),
        };
        return Padding(
          padding: EdgeInsets.only(
            top: _gap(index == 0 ? null : rows[index - 1], row),
          ),
          child: child,
        );
      },
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        TDate.day(day),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _ChatColors.of(context).hint,
        ),
      ),
    );
  }
}

class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final returned = message.kind == MessageKind.returned;
    final text = returned
        ? tr('Buyum egasiga qaytarildi · {time}', {
            'time': TDate.time(message.sentAt),
          })
        : tr('Javob yashirin belgiga mos keldi · Chat ochildi');
    return Center(
      child: Container(
        // 300 for the content, as in the design, plus the padding.
        constraints: const BoxConstraints(maxWidth: 324),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              returned ? Symbols.handshake_rounded : Symbols.key_rounded,
              size: 15,
              fill: 1,
              color: cs.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.tail,
    required this.seen,
  });

  final ChatMessage message;
  final bool tail;

  /// My message, and the other member has opened the chat since.
  final bool seen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = _ChatColors.of(context);
    final me = message.fromMe;
    final fg = me ? cs.onPrimary : cs.onSurface;
    final timeColor = me ? c.myTime : c.otherTime;
    final meta = Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            TDate.time(message.sentAt),
            style: TextStyle(fontSize: 11, height: 14 / 11, color: timeColor),
          ),
          if (me) ...[
            const SizedBox(width: 2),
            Icon(
              seen ? Symbols.done_all_rounded : Symbols.done_rounded,
              size: 14,
              color: timeColor,
            ),
          ],
        ],
      ),
    );
    const r = Radius.circular(22), t = Radius.circular(6);
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 270),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
          decoration: BoxDecoration(
            color: me ? cs.primary : cs.surfaceContainerLowest,
            borderRadius: BorderRadius.only(
              topLeft: r,
              topRight: r,
              bottomLeft: tail && !me ? t : r,
              bottomRight: tail && me ? t : r,
            ),
            boxShadow: [
              me
                  ? const BoxShadow(
                      color: Color(0x382B5FD9),
                      offset: Offset(0, 6),
                      blurRadius: 16,
                    )
                  : const BoxShadow(
                      color: Color(0x0D0F1420),
                      offset: Offset(0, 2),
                      blurRadius: 8,
                    ),
            ],
          ),
          // The time sits on the last line when it fits, otherwise on a new
          // one: an invisible copy reserves its space at the end of the text.
          child: Semantics(
            label: me ? (seen ? tr('Oʻqildi') : tr('Yuborildi')) : null,
            child: Stack(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: message.text),
                      WidgetSpan(
                        child: ExcludeSemantics(
                          child: Visibility.maintain(
                            visible: false,
                            child: meta,
                          ),
                        ),
                      ),
                    ],
                  ),
                  style: TextStyle(fontSize: 16, height: 21 / 16, color: fg),
                ),
                Positioned(right: 0, bottom: 0, child: meta),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({super.key});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _empty => _controller.text.trim().isEmpty;

  bool _wasEmpty = true;

  void _onChanged() {
    if (_empty != _wasEmpty) setState(() => _wasEmpty = _empty);
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
    final c = _ChatColors.of(context);
    final empty = _empty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: GlassSurface(
            radius: 24,
            color: c.glassBar,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Center(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 16,
                    height: 21 / 16,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: tr('Xabar yozing…'),
                    hintStyle: TextStyle(fontSize: 16, color: c.hint),
                    filled: false,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          enabled: !empty,
          label: tr('Yuborish'),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: empty ? null : _send,
            child: Opacity(
              opacity: empty ? 0.45 : 1,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D2B5FD9),
                      offset: Offset(0, 8),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  Symbols.arrow_upward_rounded,
                  size: 24,
                  color: cs.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClosedBar extends StatelessWidget {
  const _ClosedBar({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = _ChatColors.of(context);
    return GlassSurface(
      color: c.glassBar,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          children: [
            Icon(Symbols.lock_rounded, size: 20, fill: 1, color: c.hint),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tr('Chat yopildi.'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(text: tr('Yozishmalar saqlanadi.')),
                  ],
                ),
                style: TextStyle(
                  fontSize: 14,
                  height: 18 / 14,
                  color: cs.secondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push(Routes.listing(listingId)),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tr('Eʼlonni koʻrish'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
