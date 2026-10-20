import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/listing_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_chip.dart';
import '../../domain/entities/listing.dart';
import '../category_ui.dart';
import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../cubit/feed_cubit.dart';
import '../widgets/filters_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FeedCubit>()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: BlocBuilder<FeedCubit, FeedState>(
              builder: (context, state) {
                final cubit = context.read<FeedCubit>();
                return switch (state.view) {
                  ViewLoading() => const CardsSkeleton(),
                  ViewEmpty() when !state.filter.isDefault || state.search.isNotEmpty => EmptyState(
                      icon: Symbols.search_off_rounded,
                      title: 'Hech narsa topilmadi',
                      body: 'Filtrlarni oʻzgartiring yoki boshqa soʻz bilan qidiring.',
                      cta: 'Filtrlarni tozalash',
                      onCta: cubit.resetFilter,
                    ),
                  ViewEmpty() => EmptyState(
                      icon: Symbols.inventory_2_rounded,
                      title: 'Hozircha eʼlon yoʻq',
                      body: 'Bu hududda hali hech kim eʼlon bermagan. Birinchi boʻling!',
                      cta: 'Eʼlon berish',
                      onCta: () => context.push(Routes.create),
                    ),
                  ViewError(:final isOffline) =>
                    isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load),
                  ViewLoaded(:final data) => _FeedList(page: data, type: state.type, onRefresh: () => cubit.load(silent: true)),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  Future<void> _openFilters(BuildContext context) async {
    final cubit = context.read<FeedCubit>();
    final s = cubit.state;
    final picked = await showFiltersSheet(context, filter: s.filter, type: s.type, search: s.search);
    if (picked != null) cubit.setFilter(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<FeedCubit>();
    final filter = context.select<FeedCubit, ListingFilter>((c) => c.state.filter);

    return Material(
      color: cs.surfaceContainerLowest,
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant))),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: TSpace.md, bottom: TSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TSpace.screen),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _openFilters(context),
                          borderRadius: BorderRadius.circular(TRadius.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Joylashuv',
                                  style: text.bodySmall!.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      filter.district == null ? filter.city : '${filter.city}, ${filter.district}',
                                      overflow: TextOverflow.ellipsis,
                                      style: text.titleMedium!.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Symbols.keyboard_arrow_down_rounded, size: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: TSpace.xs),
                      BlocBuilder<NotificationBadgeCubit, int>(
                        builder: (context, unread) => _SquareButton(
                          icon: Symbols.notifications_rounded,
                          semantic: unread > 0 ? 'Bildirishnomalar, $unread ta yangi' : 'Bildirishnomalar',
                          dot: unread > 0,
                          onTap: () => context.push(Routes.notifications),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TSpace.screen),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: TSize.tapTarget,
                          child: TextField(
                            onChanged: cubit.setSearch,
                            textInputAction: TextInputAction.search,
                            style: text.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Nimani qidiryapsiz?',
                              fillColor: cs.surfaceContainerHigh,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                              prefixIcon: Icon(Symbols.search_rounded, size: 20, color: cs.onSurfaceVariant),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(TRadius.md), borderSide: BorderSide.none),
                              enabledBorder:
                                  OutlineInputBorder(borderRadius: BorderRadius.circular(TRadius.md), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: TSpace.xs),
                      _SquareButton(
                        icon: Symbols.tune_rounded,
                        semantic: filter.isDefault ? 'Filtrlar' : 'Filtrlar, faol',
                        color: cs.primary,
                        dot: !filter.isDefault,
                        dotColor: cs.primary,
                        onTap: () => _openFilters(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                BlocSelector<FeedCubit, FeedState, ListingType>(
                  selector: (s) => s.type,
                  builder: (context, type) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: TSpace.screen),
                    child: TTypeTabs(
                      isFound: type == ListingType.found,
                      onChanged: (found) => cubit.setType(found ? ListingType.found : ListingType.lost),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                BlocSelector<FeedCubit, FeedState, Set<ItemCategory>>(
                  selector: (s) => s.filter.categories,
                  builder: (context, cats) => TChipRow(
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
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.semantic,
    required this.onTap,
    this.color,
    this.dot = false,
    this.dotColor,
  });

  final IconData icon;
  final String semantic;
  final VoidCallback onTap;
  final Color? color, dotColor;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TRadius.md),
          side: BorderSide(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: TSize.tapTarget,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 24, color: color ?? cs.onSurface),
                if (dot)
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor ?? cs.error,
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

class _FeedList extends StatelessWidget {
  const _FeedList({required this.page, required this.type, required this.onRefresh});

  final ListingPage page;
  final ListingType type;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final countLabel = type == ListingType.found ? '${page.total} ta topilgan buyum' : '${page.total} ta yoʻqolgan buyum';
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(TSpace.screen, TSpace.sm, TSpace.screen, TSpace.xs),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      countLabel,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
                    ),
                  ),
                  TSegmented(
                    items: const [(Symbols.list_rounded, 'Roʻyxat'), (Symbols.map_rounded, 'Xarita')],
                    selected: 0,
                    onChanged: (i) {
                      if (i == 1) context.go(Routes.map);
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(TSpace.screen, 0, TSpace.screen, TSpace.md),
            sliver: SliverList.separated(
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final l = page.items[i];
                return ListingCard(
                  title: l.title,
                  category: l.category.label,
                  meta: '${l.areaName.split(',').first} · ${TDate.relative(l.happenedAt)}',
                  isFound: l.isFound,
                  icon: l.category.icon,
                  tint: l.tint,
                  onTap: () => context.push(Routes.listing(l.id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
