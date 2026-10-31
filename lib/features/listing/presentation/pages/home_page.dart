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
import '../../../../core/widgets/glass_header.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_chip.dart';
import '../../../../core/widgets/t_refresh_scroll_view.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../domain/entities/listing.dart';
import '../category_ui.dart';
import '../cubit/feed_cubit.dart';
import '../widgets/feed_empty_state.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/returned_strip.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/l10n/tr.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<FeedCubit>()..load(), child: const _HomeView());
  }
}

const _side = GlassHeader.side;

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
    final barTop = GlassHeader.top(context);
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
                SliverToBoxAdapter(child: GlassLargeTitle(tr('Lenta'))),
                SliverPersistentHeader(pinned: true, delegate: _PinnedTabs(offset: _offset)),
                // Above the feed and outside _content: the proof is worth
                // most when the feed below it is still loading or empty.
                // AnimatedSize grows it in when the items land, and folds it
                // away when a category chip leaves too few, so the feed
                // below never jumps.
                SliverToBoxAdapter(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: state.showReturned
                        ? ReturnedStrip(items: state.visibleReturned)
                        : const SizedBox(width: double.infinity),
                  ),
                ),
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
      ViewLoading() => [_grid(bottom, itemCount: 6, itemBuilder: (_, _) => const FeedGridCardSkeleton())],
      // Only a category chip narrows the feed: say so, with that category's icon.
      ViewEmpty() when _onlyCategory(state) != null => [
        FeedEmptySliver(
          lost: state.type == ListingType.lost,
          icon: _onlyCategory(state)!.icon,
          title: tr('Bu toifada eʼlon yoʻq'),
          lead: tr('Boshqa toifani tanlang yoki birinchi boʻling — pastdagi '),
        ),
      ],
      ViewEmpty() when !state.filter.isDefault || state.search.isNotEmpty => [
        fill(
          EmptyState(
            icon: Symbols.search_off_rounded,
            title: tr('Hech narsa topilmadi'),
            body: tr('Filtrlarni oʻzgartiring yoki boshqa soʻz bilan qidiring.'),
            cta: tr('Filtrlarni tozalash'),
            onCta: cubit.resetFilter,
          ),
        ),
      ],
      ViewEmpty() => [
        FeedEmptySliver(
          lost: state.type == ListingType.lost,
          title: state.type == ListingType.lost ? tr('Hozircha yoʻqolgan narsa yoʻq') : tr('Hozircha eʼlon yoʻq'),
          lead: tr('Bu hududda hali hech kim eʼlon bermagan. Birinchi boʻling — pastdagi '),
        ),
      ],
      ViewError(:final isOffline) => [
        fill(isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load)),
      ],
      ViewLoaded(:final data) => [
        _grid(
          bottom,
          itemCount: data.items.length,
          itemBuilder: (context, i) {
            final l = data.items[i];
            final meta = '${l.category.label} · ${l.areaName.split(',').first}';
            final time = TDate.relative(l.happenedAt);
            return FeedGridCard(
              title: l.title,
              meta: meta,
              time: time,
              tag: GlassTag.type(context, isFound: l.isFound),
              semanticLabel: '${l.isFound ? tr('Topilgan') : tr('Yoʻqolgan')}. ${l.title}. $meta. $time',
              icon: l.category.icon,
              tint: l.tint,
              imagePath: l.photoAt(0),
              onTap: () => context.push(Routes.listing(l.id)),
            );
          },
        ),
      ],
    };
  }

  /// The single category chosen when that is the only narrowing; null otherwise.
  static ItemCategory? _onlyCategory(FeedState state) {
    final cats = state.filter.categories;
    if (state.search.isNotEmpty || cats.length != 1) return null;
    return state.filter.copyWith(categories: const {}).isDefault ? cats.first : null;
  }

  /// Two columns (three on wide screens); cells sized by [FeedGridCard.extent].
  Widget _grid(double bottom, {required int itemCount, required NullableIndexedWidgetBuilder itemBuilder}) {
    const gap = 12.0;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(_side, 6, _side, bottom + 12),
      sliver: SliverLayoutBuilder(
        builder: (context, c) {
          final columns = c.crossAxisExtent >= 600 ? 3 : 2;
          final width = (c.crossAxisExtent - gap * (columns - 1)) / columns;
          return SliverGrid.builder(
            itemCount: itemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              mainAxisExtent: FeedGridCard.extent(width, MediaQuery.textScalerOf(context)),
            ),
            itemBuilder: itemBuilder,
          );
        },
      ),
    );
  }
}

Future<void> _openFilters(BuildContext context) async {
  final cubit = context.read<FeedCubit>();
  final s = cubit.state;
  final picked = await showFiltersSheet(context, filter: s.filter, type: s.type, search: s.search);
  if (picked != null) cubit.setFilter(picked);
}

/// Pinned row of glass buttons: location capsule left, Filtrlar and
/// Bildirishnomalar right; the inline "Lenta" fades in once the large
/// title has scrolled under it.
class _TopBar extends SliverPersistentHeaderDelegate {
  const _TopBar({required this.top, required this.offset});

  static const height = GlassHeader.barHeight;

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
    return GlassBarBackground(
      child: BlocSelector<FeedCubit, FeedState, ListingFilter>(
        selector: (s) => s.filter,
        builder: (context, filter) => Padding(
          padding: EdgeInsets.fromLTRB(_side, top, _side, 8),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.5),
                child: _LocationCapsule(label: tr(filter.district ?? filter.city), onTap: () => _openFilters(context)),
              ),
              Expanded(child: GlassInlineTitle(tr('Lenta'), offset: offset)),
              GlassCircleButton(
                icon: Symbols.tune_rounded,
                semantic: filter.isDefault ? tr('Filtrlar') : tr('Filtrlar, faol'),
                dot: filter.isDefault ? null : cs.primary,
                onTap: () => _openFilters(context),
              ),
              const SizedBox(width: 8),
              BlocBuilder<NotificationBadgeCubit, int>(
                builder: (context, unread) => GlassCircleButton(
                  icon: Symbols.notifications_rounded,
                  semantic: unread > 0
                      ? tr('Bildirishnomalar, {unread} ta yangi', {'unread': unread})
                      : tr('Bildirishnomalar'),
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
    return GlassBarBackground(
      offset: offset,
      hairlineAt: GlassHeader.titleExtent - 1,
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
                labels: [tr('Hammasi'), for (final c in feedCategories) c.label],
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
      label: tr('Joylashuv: {label}', {'label': label}),
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
