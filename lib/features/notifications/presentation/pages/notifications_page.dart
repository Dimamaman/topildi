import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/glass_empty_icon.dart';
import '../../../../core/widgets/glass_header.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_refresh_scroll_view.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../../../../core/l10n/tr.dart';

const _title = 'Bildirishnomalar';
const _side = GlassHeader.side;

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<NotificationsCubit>()..load(), child: const _NotificationsView());
  }
}

/// iOS 26 style: glass back button and "Hammasi oʻqildi" pinned on top,
/// a large title that collapses into the bar, and notifications in white
/// inset groups (Bugun / Shu hafta / Oldinroq).
class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  final _offset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<NotificationsCubit>();
    final top = GlassHeader.top(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.depth == 0 && n.metrics.axis == Axis.vertical) _offset.value = n.metrics.pixels;
            return false;
          },
          child: BlocBuilder<NotificationsCubit, ViewState<List<AppNotification>>>(
            builder: (context, state) {
              final hasUnread = state is ViewLoaded<List<AppNotification>> && state.data.any((n) => !n.read);
              return TRefreshScrollView(
                onRefresh: () => cubit.load(silent: true),
                edgeOffset: top + GlassHeader.barHeight,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _Bar(top: top, offset: _offset, onReadAll: hasUnread ? cubit.markAllRead : null),
                  ),
                  SliverToBoxAdapter(child: GlassLargeTitle(tr(_title), oneLine: true)),
                  ..._body(context, state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, ViewState<List<AppNotification>> state) {
    final cubit = context.read<NotificationsCubit>();
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    Widget fill(Widget child) => SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: child,
      ),
    );
    return switch (state) {
      ViewLoading() => [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(_side, 6, _side, bottom),
          sliver: const SliverToBoxAdapter(child: _GroupSkeleton()),
        ),
      ],
      ViewEmpty() => [fill(const _Empty())],
      ViewError(:final isOffline) => [
        fill(isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load)),
      ],
      ViewLoaded(:final data) => [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(_side, 0, _side, bottom),
          sliver: SliverList.list(children: _grouped(data)),
        ),
      ],
    };
  }

  List<Widget> _grouped(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groups = <String, List<AppNotification>>{tr('Bugun'): [], tr('Shu hafta'): [], tr('Oldinroq'): []};
    for (final n in items) {
      final d = n.createdAt;
      final key = !d.isBefore(today) ? tr('Bugun') : (today.difference(d).inDays < 7 ? tr('Shu hafta') : tr('Oldinroq'));
      groups[key]!.add(n);
    }
    var first = true;
    final out = <Widget>[];
    for (final g in groups.entries) {
      if (g.value.isEmpty) continue;
      out
        ..add(_SectionTitle(g.key, top: first ? 6 : 22))
        ..add(
          _Group(
            children: [for (var i = 0; i < g.value.length; i++) _Row(n: g.value[i], divider: i < g.value.length - 1)],
          ),
        );
      first = false;
    }
    return out;
  }
}

/// Pinned glass bar: back button, inline title, "Hammasi oʻqildi".
class _Bar extends SliverPersistentHeaderDelegate {
  const _Bar({required this.top, required this.offset, required this.onReadAll});

  final double top;
  final ValueListenable<double> offset;

  /// Null when everything is read: the capsule is hidden.
  final VoidCallback? onReadAll;

  @override
  double get minExtent => top + GlassHeader.barHeight;

  @override
  double get maxExtent => top + GlassHeader.barHeight;

  @override
  bool shouldRebuild(covariant _Bar old) =>
      old.top != top || old.offset != offset || (old.onReadAll == null) != (onReadAll == null);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    final label = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: 15, height: 20 / 15, color: cs.primary).inter(FontWeight.w600);
    return GlassBarBackground(
      offset: offset,
      hairlineAt: GlassHeader.titleExtent - 1,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: Padding(
          padding: EdgeInsets.fromLTRB(_side, top, _side, 8),
          child: ValueListenableBuilder<double>(
            valueListenable: offset,
            builder: (context, o, _) {
              // Once the inline title shows, "Hammasi oʻqildi" shrinks to its icon so the title fits centred.
              final compact = GlassHeader.inlineOpacity(o) > 0;
              return Row(
                children: [
                  GlassCircleButton(
                    icon: Symbols.chevron_left_rounded,
                    iconSize: 24,
                    semantic: tr('Orqaga'),
                    onTap: () => context.canPop() ? context.pop() : context.go(Routes.home),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: compact ? GlassInlineTitle(tr(_title), offset: offset) : const SizedBox.shrink()),
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: onReadAll == null ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: onReadAll == null,
                      child: Semantics(
                        button: true,
                        label: tr('Hammasi oʻqildi'),
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: onReadAll,
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            height: 44,
                            child: GlassSurface(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 12, right: compact ? 12 : 16),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Symbols.done_all_rounded, size: 20, color: cs.primary),
                                      if (!compact) ...[
                                        const SizedBox(width: 6),
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            // Bar width minus back button, gaps and the capsule's icon + padding.
                                            maxWidth: MediaQuery.sizeOf(context).width - 2 * _side - 44 - 16 - 54 - 4,
                                          ),
                                          child: Text(
                                            tr('Hammasi oʻqildi'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: label,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// "BUGUN"-style caption.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.top});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, top, 18, 6),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 13,
            height: 18 / 13,
            letterSpacing: 0.2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _Row extends StatelessWidget {
  const _Row({required this.n, required this.divider});

  final AppNotification n;
  final bool divider;

  String _time(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return tr('Hozirgina');
    if (diff.inMinutes < 60) return tr('{n} daqiqa oldin', {'n': diff.inMinutes});
    if (diff.inHours < 24 && now.day == d.day) return tr('{n} soat oldin', {'n': diff.inHours});
    return TDate.relative(d, withTimeForOld: true);
  }

  void _go(BuildContext context) {
    context.read<NotificationsCubit>().open(n);
    switch (n.target) {
      case OpenClaims(:final listingId):
        context.push(Routes.claims(listingId));
      case OpenChat(:final chatId):
        context.push(Routes.chat(chatId));
      case OpenListing(:final listingId):
        context.push(Routes.listing(listingId));
      case OpenSuccess(:final chatId):
        context.push(Routes.success(chatId));
    }
  }

  static String textOf(AppNotification n) => switch (n.kind) {
    NotificationKind.newClaim => tr('“{title}” eʼloningizga yangi soʻrov keldi. Javobni tekshiring.', {
      'title': n.listingTitle,
    }),
    NotificationKind.claimAccepted => tr('{name} soʻrovingizni qabul qildi. Chatda kelishib oling.', {
      'name': n.actorName,
    }),
    NotificationKind.claimRejected when n.attemptsLeft > 0 => tr(
      '“{title}” boʻyicha soʻrovingiz rad etildi. Yana {n} ta urinishingiz bor.',
      {'title': n.listingTitle, 'n': n.attemptsLeft},
    ),
    NotificationKind.claimRejected => tr('“{title}” boʻyicha soʻrovingiz rad etildi.', {'title': n.listingTitle}),
    NotificationKind.returned => tr('{finderName} buyumingizni qaytardi. Unga rahmat aytishni unutmang!', {
      'finderName': n.actorName,
    }),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final (icon, size, filled, bg, fg) = switch (n.kind) {
      NotificationKind.newClaim => (Symbols.verified_user_rounded, 20.0, true, cs.primaryContainer, cs.primary),
      NotificationKind.claimAccepted => (Symbols.check_rounded, 22.0, false, tc.successContainer, tc.success),
      NotificationKind.claimRejected => (Symbols.close_rounded, 22.0, false, tc.lostContainer, tc.lost),
      NotificationKind.returned => (Symbols.favorite_rounded, 20.0, true, tc.successContainer, tc.success),
    };
    final message = textOf(n);
    final unread = !n.read;
    final time = _time(n.createdAt);
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${unread ? tr('Oʻqilmagan. ') : ''}$message. $time',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _go(context),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: size, color: fg, fill: filled ? 1 : 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
                  decoration: divider
                      ? BoxDecoration(
                          border: Border(bottom: BorderSide(color: context.ts.separator, width: 0.5)),
                        )
                      : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: unread
                                  ? text.bodyLarge!
                                        .copyWith(fontSize: 15, height: 20 / 15, color: cs.onSurface)
                                        .inter(FontWeight.w600)
                                  : text.bodyLarge!.copyWith(fontSize: 15, height: 20 / 15, color: cs.secondary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              time,
                              style: text.bodySmall!.copyWith(
                                fontSize: 13,
                                height: 18 / 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Unread dot (also announced as "Oʻqilmagan").
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: unread ? cs.primary : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
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

/// Nothing yet: the shared glass bell, a title, three sample rows of what
/// will arrive here (fading out), and "Bildirishnoma sozlamalari" at the
/// bottom. A warning card leads when notifications are off in the system.
class _Empty extends StatefulWidget {
  const _Empty();

  @override
  State<_Empty> createState() => _EmptyState();
}

class _EmptyState extends State<_Empty> with WidgetsBindingObserver {
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the system settings: the switch may have changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final blocked = await getIt<PushService>().blocked;
    if (mounted && blocked != _blocked) setState(() => _blocked = blocked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    // The app's real notification kinds; see _Row.
    final samples = [
      (
        Symbols.front_hand_rounded,
        cs.primary,
        cs.primaryContainer,
        tr('Yangi soʻrov'),
        tr('Kimdir buyum oʻziniki ekanini aytdi'),
      ),
      (
        Symbols.forum_rounded,
        tc.success,
        tc.successContainer,
        tr('Soʻrov qabul qilindi'),
        tr('Chatda uchrashuvni kelishasiz'),
      ),
      (
        Symbols.favorite_rounded,
        tc.lost,
        tc.lostContainer,
        tr('Buyum qaytarildi'),
        tr('Topuvchi buyumingizni sizga qaytardi'),
      ),
    ];
    return Column(
      children: [
        const SizedBox(height: 4),
        const GlassEmptyIcon(icon: Symbols.notifications_rounded, iconSize: 60, badge: GlassIconBadge.none),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Semantics(
                header: true,
                child: Text(
                  tr('Yangi xabar yoʻq'),
                  textAlign: TextAlign.center,
                  style: text.headlineSmall!
                      .copyWith(fontSize: 24, height: 30 / 24, letterSpacing: -0.4, color: cs.onSurface)
                      .inter(FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('Bu yerda shunday xabarlar chiqadi:'),
                textAlign: TextAlign.center,
                style: text.bodyMedium!
                    .copyWith(fontSize: 15, height: 21 / 15, color: cs.onSurfaceVariant)
                    .inter(FontWeight.w400),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              if (_blocked) ...[const _BlockedCard(), const SizedBox(height: 12)],
              Semantics(
                label: tr('Bu yerda chiqadigan xabarlar: {list}', {
                  'list': [for (final s in samples) '${s.$4}. ${s.$5}'].join('; '),
                }),
                excludeSemantics: true,
                child: IgnorePointer(
                  child: Column(
                    children: [
                      for (var i = 0; i < samples.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        Opacity(
                          opacity: const [1.0, 0.75, 0.5][i],
                          child: _SampleRow(
                            icon: samples[i].$1,
                            fg: samples[i].$2,
                            bg: samples[i].$3,
                            title: samples[i].$4,
                            body: samples[i].$5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const SizedBox(height: 24),
        Semantics(
          button: true,
          child: GestureDetector(
            onTap: () => context.go(Routes.profile),
            child: Container(
              height: 44,
              padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.tune_rounded, size: 20, color: cs.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      tr('Bildirishnoma sozlamalari'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, color: cs.onPrimaryContainer).inter(FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// One sample of what will show up, white card with a tinted icon square.
class _SampleRow extends StatelessWidget {
  const _SampleRow({required this.icon, required this.fg, required this.bg, required this.title, required this.body});

  final IconData icon;
  final Color fg, bg;
  final String title, body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A0F1420), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 22, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, color: cs.onSurface).inter(FontWeight.w700)),
                Text(body, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant).inter(FontWeight.w400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Notifications are off in the system: say so, with "Yoqish" to the
/// app's settings page.
class _BlockedCard extends StatelessWidget {
  const _BlockedCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(color: tc.warningContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(Symbols.notifications_off_rounded, size: 22, color: tc.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('Bildirishnomalar oʻchiq — yangi xabarlarni oʻtkazib yuborishingiz mumkin'),
              style: TextStyle(fontSize: 13, height: 18 / 13, color: cs.onSurface).inter(FontWeight.w500),
            ),
          ),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => getIt<LocationService>().openSettings(),
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text(tr('Yoqish'), style: TextStyle(fontSize: 14, color: cs.primary).inter(FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading: one group of skeleton rows in the same shape.
class _GroupSkeleton extends StatelessWidget {
  const _GroupSkeleton();

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
    return _Group(
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: ts.skeleton, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      bar(0.9, 14, ts.skeleton),
                      const SizedBox(height: 8),
                      bar(0.4, 12, ts.skeletonSoft),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
