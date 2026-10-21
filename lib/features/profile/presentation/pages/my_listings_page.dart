import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/feed_card.dart';
import '../../../../core/widgets/glass_header.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_chip.dart';
import '../../../../core/widgets/t_refresh_scroll_view.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/profile_summary.dart';
import '../cubit/profile_cubit.dart';
import '../../../../core/l10n/tr.dart';

const _title = 'Mening eʼlonlarim';
const _side = GlassHeader.side;

/// Room under the last card so the floating "Eʼlon berish" never covers it.
const _fabClearance = 110.0;

/// "Mening eʼlonlarim" — every own listing with a Faol / Qaytarilgan filter.
/// Opened from "Hammasi" on the Profil page. iOS 26 style: glass back
/// button, collapsing large title, capsule segmented control, photo cards
/// and a floating "Eʼlon berish" capsule that shrinks to "+" while scrolling down.
class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<ProfileCubit>()..load(), child: const _MyListingsView());
  }
}

class _MyListingsView extends StatefulWidget {
  const _MyListingsView();

  @override
  State<_MyListingsView> createState() => _MyListingsViewState();
}

class _MyListingsViewState extends State<_MyListingsView> {
  final _offset = ValueNotifier<double>(0);
  final _fabExtended = ValueNotifier<bool>(true);

  /// Last loaded counts, so the tabs keep them while a tab switch reloads.
  ({int active, int returned})? _counts;

  /// Like the Lenta type tabs: switching reloads the list, showing the
  /// skeleton cards until it arrives.
  void _switchTab(bool returned) {
    final cubit = context.read<ProfileCubit>();
    if (cubit.state.showReturned == returned) return;
    cubit.showTab(returned: returned);
    cubit.load();
  }

  @override
  void dispose() {
    _offset.dispose();
    _fabExtended.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    _offset.value = n.metrics.pixels;
    if (n is UserScrollNotification) {
      if (n.direction == ScrollDirection.reverse) _fabExtended.value = false;
      if (n.direction == ScrollDirection.forward) _fabExtended.value = true;
    }
    // Always full-size once back at the top.
    if (n is ScrollEndNotification && n.metrics.pixels <= 0) _fabExtended.value = true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<ProfileCubit>();
    final top = GlassHeader.top(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) => TRefreshScrollView(
                  onRefresh: () => cubit.load(silent: true),
                  edgeOffset: top + GlassHeader.barHeight,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _BackBar(top: top, offset: _offset),
                    ),
                    SliverToBoxAdapter(child: GlassLargeTitle(tr(_title))),
                    ..._body(context, state),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: math.max(28, bottomInset - 6),
              child: Center(child: _AddButton(extended: _fabExtended)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, ProfileState state) {
    final cubit = context.read<ProfileCubit>();
    final bottom = MediaQuery.paddingOf(context).bottom + _fabClearance;
    Widget fill(Widget child) => SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(padding: EdgeInsets.only(bottom: bottom - 40), child: child),
    );
    if (state.view case ViewLoaded(:final data)) {
      _counts = (active: data.active.length, returned: data.returned.length);
    }
    return switch (state.view) {
      ViewLoading() || ViewEmpty() => [
        SliverToBoxAdapter(
          child: _Tabs(
            active: _counts?.active,
            returned: _counts?.returned,
            showReturned: state.showReturned,
            onChanged: _switchTab,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(_side, 18, _side, bottom),
          sliver: SliverList.separated(
            itemCount: 2,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, _) => const FeedCardSkeleton(photoHeight: 150),
          ),
        ),
      ],
      ViewError(isOffline: true) => [
        const SliverToBoxAdapter(child: OfflineBanner()),
        fill(
          MessageState(
            icon: Symbols.wifi_off_rounded,
            title: tr('Eʼlonlar yuklanmadi'),
            body: tr('Internet yoʻq. Ulanish qaytgach, roʻyxat yangilanadi.'),
            cta: tr('Qayta urinish'),
            onCta: cubit.load,
            circle: context.tc.warningContainer,
            fg: context.tc.warning,
          ),
        ),
      ],
      ViewError() => [
        fill(
          MessageState(
            icon: Symbols.error_rounded,
            title: tr('Eʼlonlar yuklanmadi'),
            body: tr('Roʻyxatni olib boʻlmadi. Birozdan soʻng qayta urinib koʻring.'),
            cta: tr('Qayta urinish'),
            onCta: cubit.load,
            circle: Theme.of(context).colorScheme.errorContainer,
            fg: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
      ViewLoaded(:final data) => [
        SliverToBoxAdapter(
          child: _Tabs(
            active: data.active.length,
            returned: data.returned.length,
            showReturned: state.showReturned,
            onChanged: _switchTab,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(top: 18, bottom: bottom),
          sliver: SliverToBoxAdapter(
            child: _CardList(data: data, showReturned: state.showReturned, onSwipe: _switchTab),
          ),
        ),
      ],
    };
  }
}

/// Pinned glass bar: back button, and the inline title once the large one is gone.
class _BackBar extends SliverPersistentHeaderDelegate {
  const _BackBar({required this.top, required this.offset});

  final double top;
  final ValueListenable<double> offset;

  @override
  double get minExtent => top + GlassHeader.barHeight;

  @override
  double get maxExtent => top + GlassHeader.barHeight;

  @override
  bool shouldRebuild(covariant _BackBar old) => old.top != top || old.offset != offset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return GlassBarBackground(
      offset: offset,
      hairlineAt: GlassHeader.titleExtent - 1,
      child: Padding(
        padding: EdgeInsets.fromLTRB(_side, top, _side, 8),
        child: Row(
          children: [
            GlassCircleButton(
              icon: Symbols.chevron_left_rounded,
              iconSize: 24,
              semantic: tr('Orqaga'),
              onTap: () => context.canPop() ? context.pop() : context.go(Routes.profile),
            ),
            const SizedBox(width: 8),
            Expanded(child: GlassInlineTitle(tr(_title), offset: offset)),
            // Mirrors the back button so the inline title stays centred.
            const SizedBox(width: 8 + 44),
          ],
        ),
      ),
    );
  }
}

/// "Faol · N" / "Qaytarilgan · N". Counts are null while loading.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.active, required this.returned, required this.showReturned, required this.onChanged});

  final int? active, returned;
  final bool showReturned;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    String label(String name, int? n) => n == null ? name : '$name · $n';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _side),
      child: TCapsuleSegmented(
        selected: showReturned ? 1 : 0,
        onChanged: (i) => onChanged(i == 1),
        segments: [
          (label: label(tr('Faol'), active), color: null),
          (label: label(tr('Qaytarilgan'), returned), color: null),
        ],
      ),
    );
  }
}

/// Cards of the selected tab; a horizontal swipe switches tabs.
class _CardList extends StatelessWidget {
  const _CardList({required this.data, required this.showReturned, required this.onSwipe});

  final ProfileSummary data;
  final bool showReturned;
  final ValueChanged<bool> onSwipe;

  @override
  Widget build(BuildContext context) {
    final items = showReturned ? data.returned : data.active;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -300 && !showReturned) onSwipe(true);
        if (v > 300 && showReturned) onSwipe(false);
      },
      child: items.isEmpty
          ? _Empty(returned: showReturned)
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: _side),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _MineCard(m: items[i]),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.returned});

  final bool returned;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: returned
          ? MessageState(
              icon: Symbols.task_alt_rounded,
              title: tr('Hali qaytarilgan buyum yoʻq'),
              body: tr('Buyumni egasiga topshirganingizda shu yerda koʻrinadi.'),
              circle: tc.successContainer,
              fg: tc.success,
            )
          : MessageState(
              icon: Symbols.campaign_rounded,
              title: tr('Faol eʼlon yoʻq'),
              body: tr('Biror narsa topdingizmi yoki yoʻqotdingizmi? Eʼlon bering.'),
              circle: cs.primaryContainer,
              fg: cs.onPrimaryContainer,
            ),
    );
  }
}

class _MineCard extends StatelessWidget {
  const _MineCard({required this.m});

  final MyListing m;

  @override
  Widget build(BuildContext context) {
    final l = m.listing;
    final meta = '${l.areaName.split(',').first} · ${TDate.day(l.happenedAt)}';
    final status = _statusTag(context);
    return FeedCard(
      title: l.title,
      meta: meta,
      icon: l.category.icon,
      tint: l.tint,
      imagePath: l.photoAt(0),
      photoHeight: 150,
      iconSize: 60,
      leadingTag: status,
      trailingTag: GlassTag.type(context, isFound: l.isFound),
      semanticLabel: '${status.label}. ${l.isFound ? tr('Topilgan') : tr('Yoʻqolgan')}. ${l.title}. $meta',
      // Author view of the listing (claims are reachable from there).
      onTap: () => context.push(Routes.listing(l.id)),
    );
  }

  GlassTag _statusTag(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (m.listing.status == ListingStatus.returned) {
      return GlassTag(
        label: tr('Qaytarildi'),
        icon: Symbols.task_alt_rounded,
        color: tc.success,
        fill: tc.successContainer.withValues(alpha: dark ? 0.85 : 0.9),
      );
    }
    if (m.pendingClaims > 0) {
      return GlassTag(
        label: tr('Soʻrov bor · {pendingClaims}', {'pendingClaims': m.pendingClaims}),
        icon: Symbols.inbox_rounded,
        color: tc.warning,
        fill: tc.warningContainer.withValues(alpha: dark ? 0.85 : 0.92),
      );
    }
    return GlassTag(
      label: tr('Faol'),
      color: cs.onPrimaryContainer,
      fill: cs.primaryContainer.withValues(alpha: dark ? 0.85 : 0.9),
    );
  }
}

/// Floating "Eʼlon berish" capsule; shrinks to a 56dp "+" circle while
/// scrolling down and grows back when scrolling up.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.extended});

  final ValueListenable<bool> extended;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: tr('Eʼlon berish'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.push(Routes.create),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 56,
          child: GlassSurface(
            color: cs.primary.withValues(alpha: dark ? 0.92 : 0.9),
            child: ValueListenableBuilder<bool>(
              valueListenable: extended,
              builder: (context, ext, _) => TweenAnimationBuilder<double>(
                tween: Tween(end: ext ? 1 : 0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => Padding(
                  padding: EdgeInsets.only(left: lerpDouble(16, 18, t)!, right: lerpDouble(16, 24, t)!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.add_rounded, size: 24, color: cs.onPrimary),
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: t,
                          child: Opacity(
                            opacity: t,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                tr('Eʼlon berish'),
                                maxLines: 1,
                                softWrap: false,
                                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(fontSize: 16, height: 20 / 16, color: cs.onPrimary)
                                    .inter(FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
