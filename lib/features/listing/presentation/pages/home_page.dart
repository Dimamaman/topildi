import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/feed_card.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_chip.dart';
import '../../../../core/widgets/t_refresh_scroll_view.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../domain/entities/listing.dart';
import '../category_ui.dart';
import '../cubit/feed_cubit.dart';
import '../widgets/filters_sheet.dart';
import '../../../../core/theme/t_text.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<FeedCubit>()..load(), child: const _HomeView());
  }
}

const _side = 16.0;

/// Large title block: 14 above (split 8 in the bar + 6 here), 41 line, 14 below.
const _titleTop = 6.0, _titleLine = 41.0, _titleBottom = 14.0;
const _titleExtent = _titleTop + _titleLine + _titleBottom;

/// Lenta, iOS 26 style. One scroll view: the glass buttons stay pinned at
/// the top, the large "Lenta" title scrolls under them and turns into an
/// inline title, the Topilgan/Yoʻqolgan control and category chips pin
/// below, the cards scroll under everything and under the floating tab bar.
class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final _offset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<FeedCubit>();
    final top = MediaQuery.paddingOf(context).top;
    final barTop = top + (top < 30 ? 8 : 0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.depth == 0 && n.metrics.axis == Axis.vertical) _offset.value = n.metrics.pixels;
            return false;
          },
          child: BlocBuilder<FeedCubit, FeedState>(
            builder: (context, state) => TRefreshScrollView(
              onRefresh: () => cubit.load(silent: true),
              edgeOffset: barTop + _TopBar.height + _PinnedTabs.extent,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TopBar(top: barTop, offset: _offset),
                ),
                const SliverToBoxAdapter(child: _LargeTitle()),
                SliverPersistentHeader(pinned: true, delegate: _PinnedTabs(offset: _offset)),
                ..._content(context, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, FeedState state) {
    final cubit = context.read<FeedCubit>();
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget fill(Widget child) => SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: child,
      ),
    );
    return switch (state.view) {
      ViewLoading() => [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(_side, 6, _side, bottom + 12),
          sliver: SliverList.separated(
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, _) => const FeedCardSkeleton(),
          ),
        ),
      ],
      ViewEmpty() when !state.filter.isDefault || state.search.isNotEmpty => [
        fill(
          EmptyState(
            icon: Symbols.search_off_rounded,
            title: 'Hech narsa topilmadi',
            body: 'Filtrlarni oʻzgartiring yoki boshqa soʻz bilan qidiring.',
            cta: 'Filtrlarni tozalash',
            onCta: cubit.resetFilter,
          ),
        ),
      ],
      ViewEmpty() => [
        fill(
          EmptyState(
            icon: Symbols.inventory_2_rounded,
            title: 'Hozircha eʼlon yoʻq',
            body: 'Bu hududda hali hech kim eʼlon bermagan. Birinchi boʻling!',
            cta: 'Eʼlon berish',
            onCta: () => context.push(Routes.create),
          ),
        ),
      ],
      ViewError(:final isOffline) => [
        fill(isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load)),
      ],
      ViewLoaded(:final data) => [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(_side, 6, _side, bottom + 12),
          sliver: SliverList.separated(
            itemCount: data.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final l = data.items[i];
              return FeedCard(
                title: l.title,
                meta: '${l.category.label} · ${l.areaName.split(',').first}',
                time: TDate.relative(l.happenedAt),
                isFound: l.isFound,
                icon: l.category.icon,
                tint: l.tint,
                imagePath: l.photoAt(0),
                onTap: () => context.push(Routes.listing(l.id)),
              );
            },
          ),
        ),
      ],
    };
  }
}

Future<void> _openFilters(BuildContext context) async {
  final cubit = context.read<FeedCubit>();
  final s = cubit.state;
  final picked = await showFiltersSheet(context, filter: s.filter, type: s.type, search: s.search);
  if (picked != null) cubit.setFilter(picked);
}

/// Translucent blurred page background for the pinned parts, so cards
/// scrolling underneath show through softly.
class _BarBackground extends StatelessWidget {
  const _BarBackground({required this.child, this.offset});

  final Widget child;

  /// When given, a hairline shows along the bottom once the tabs are pinned.
  final ValueListenable<double>? offset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final o = offset;
    Widget hairline(bool show) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: show ? cs.outlineVariant : Colors.transparent, width: 0.5)),
      ),
    );
    return Stack(
      children: [
        // Only the backdrop is clipped, so the glass buttons' shadows are not cut off.
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: ColoredBox(
                color: cs.surface.withValues(alpha: 0.86),
                child: o == null
                    ? const SizedBox.expand()
                    : ValueListenableBuilder<double>(
                        valueListenable: o,
                        builder: (context, v, _) => hairline(v >= _titleExtent),
                      ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Pinned row of glass buttons: location capsule left, Filtrlar and
/// Bildirishnomalar right; the inline "Lenta" fades in once the large
/// title has scrolled under it.
class _TopBar extends SliverPersistentHeaderDelegate {
  const _TopBar({required this.top, required this.offset});

  static const height = 44.0 + 8;

  final double top;
  final ValueListenable<double> offset;

  @override
  double get minExtent => top + height;

  @override
  double get maxExtent => top + height;

  @override
  bool shouldRebuild(covariant _TopBar old) => old.top != top || old.offset != offset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    return _BarBackground(
      child: BlocSelector<FeedCubit, FeedState, ListingFilter>(
        selector: (s) => s.filter,
        builder: (context, filter) => Padding(
          padding: EdgeInsets.fromLTRB(_side, top, _side, 8),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.5),
                child: _LocationCapsule(label: filter.district ?? filter.city, onTap: () => _openFilters(context)),
              ),
              Expanded(
                child: ValueListenableBuilder<double>(
                  valueListenable: offset,
                  builder: (context, o, child) =>
                      Opacity(opacity: ((o - _titleTop - _titleLine * 0.6) / 16).clamp(0.0, 1.0), child: child),
                  child: ExcludeSemantics(
                    child: Text(
                      'Lenta',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium!.copyWith(fontSize: 17, height: 22 / 17).inter(FontWeight.w600),
                    ),
                  ),
                ),
              ),
              _GlassCircle(
                icon: Symbols.tune_rounded,
                semantic: filter.isDefault ? 'Filtrlar' : 'Filtrlar, faol',
                dot: filter.isDefault ? null : cs.primary,
                onTap: () => _openFilters(context),
              ),
              const SizedBox(width: 8),
              BlocBuilder<NotificationBadgeCubit, int>(
                builder: (context, unread) => _GlassCircle(
                  icon: Symbols.notifications_rounded,
                  semantic: unread > 0 ? 'Bildirishnomalar, $unread ta yangi' : 'Bildirishnomalar',
                  dot: unread > 0 ? cs.error : null,
                  onTap: () => context.push(Routes.notifications),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeTitle extends StatelessWidget {
  const _LargeTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_side + 4, _titleTop, _side + 4, _titleBottom),
      child: Semantics(
        header: true,
        child: Text(
          'Lenta',
          maxLines: 1,
          style: Theme.of(context).textTheme.headlineMedium!
              .copyWith(fontSize: 34, height: _titleLine / 34, letterSpacing: -0.7)
              .inter(FontWeight.w700),
        ),
      ),
    );
  }
}

/// Segment + category chips; pinned under the glass buttons once they reach them.
class _PinnedTabs extends SliverPersistentHeaderDelegate {
  const _PinnedTabs({required this.offset});

  // segment 44 + gap 8 + chip row 44 (36 chips) + bottom 8
  static const extent = 44.0 + 8 + 44 + 8;

  final ValueListenable<double> offset;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  bool shouldRebuild(covariant _PinnedTabs old) => old.offset != offset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cubit = context.read<FeedCubit>();
    return _BarBackground(
      offset: offset,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlocSelector<FeedCubit, FeedState, ListingType>(
              selector: (s) => s.type,
              builder: (context, type) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: _side),
                child: TTypeTabs(
                  isFound: type == ListingType.found,
                  onChanged: (found) => cubit.setType(found ? ListingType.found : ListingType.lost),
                ),
              ),
            ),
            const SizedBox(height: 8),
            BlocSelector<FeedCubit, FeedState, Set<ItemCategory>>(
              selector: (s) => s.filter.categories,
              builder: (context, cats) => TChipRow(
                padding: const EdgeInsets.symmetric(horizontal: _side),
                labels: ['Hammasi', for (final c in feedCategories) c.label],
                // Several categories from Filters → no single chip is selected.
                selected: cats.isEmpty
                    ? 0
                    : cats.length == 1 && feedCategories.contains(cats.first)
                    ? feedCategories.indexOf(cats.first) + 1
                    : -1,
                onSelected: (i) => cubit.setCategory(i == 0 ? null : feedCategories[i - 1]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass capsule: pin + current city/district + chevron. Opens Filters.
class _LocationCapsule extends StatelessWidget {
  const _LocationCapsule({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Joylashuv: $label',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 44,
          child: GlassSurface(
            padding: const EdgeInsets.only(left: 10, right: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.location_on_rounded, size: 20, fill: 1, color: cs.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(fontSize: 15, height: 20 / 15).inter(FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Symbols.expand_more_rounded, size: 18, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 44×44 glass circle with an optional status dot (8×8, 2px rim).
class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.icon, required this.semantic, required this.onTap, this.dot});

  final IconData icon;
  final String semantic;
  final VoidCallback onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: 44,
          child: GlassSurface(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: cs.onSurface),
                if (dot != null)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      // 8×8 dot inside a 2px rim.
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surfaceContainerLowest, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
