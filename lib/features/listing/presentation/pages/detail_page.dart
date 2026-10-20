import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/t_avatar.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../../core/widgets/t_top_bar.dart';
import '../../domain/entities/listing.dart';
import '../category_ui.dart';
import '../cubit/detail_cubit.dart';
import '../widgets/area_map_card.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DetailCubit>()..load(listingId),
      child: _DetailView(listingId: listingId),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DetailCubit, DetailState>(
      builder: (context, state) {
        final cubit = context.read<DetailCubit>();
        final view = state.view;
        return Scaffold(
          appBar: TTopBar(
            title: 'Eʼlon',
            onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
            trailing: view is ViewLoaded<Listing>
                ? IconButton(
                    tooltip: 'Ulashish',
                    icon: const Icon(Symbols.share_rounded),
                    onPressed: () => TFeedback.success(context, 'Havola nusxalandi'),
                  )
                : null,
          ),
          body: switch (view) {
            ViewLoading() || ViewEmpty() => const Center(child: CircularProgressIndicator()),
            ViewError(:final failure, :final isOffline) => isOffline
                ? OfflineState(onRetry: () => cubit.load(listingId))
                : failure is NotFoundFailure
                    ? EmptyState(
                        icon: Symbols.search_off_rounded,
                        title: 'Eʼlon topilmadi',
                        body: 'Bu eʼlon oʻchirilgan yoki egasiga qaytarilgan boʻlishi mumkin.',
                        cta: 'Lentaga qaytish',
                        onCta: () => context.go(Routes.home),
                      )
                    : ErrorState(onRetry: () => cubit.load(listingId)),
            ViewLoaded(:final data) => _Content(listing: data, photoIndex: state.photoIndex),
          },
          bottomNavigationBar: view is ViewLoaded<Listing> ? _Cta(listing: view.data, isMine: state.isMine) : null,
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.listing, required this.photoIndex});

  final Listing listing;
  final int photoIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final author = listing.author;
    final roleLabel = listing.isFound ? 'Topuvchi' : 'Egasi';
    final returned = author.returnedCount > 0 ? ' · ${author.returnedCount} ta buyum qaytargan' : '';

    return ListView(
      padding: const EdgeInsets.only(bottom: TSpace.xl),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSpace.md),
          child: _Gallery(listing: listing, index: photoIndex),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(TSpace.screen, TSpace.md, TSpace.screen, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [TypeBadge(isFound: listing.isFound), CategoryBadge(label: listing.category.label)],
              ),
              const SizedBox(height: TSpace.sm),
              Text(listing.title, style: text.headlineSmall!.copyWith(letterSpacing: -0.24)),
              const SizedBox(height: TSpace.sm),
              Text(
                listing.description,
                style: text.bodyLarge!.copyWith(fontSize: 15, height: 23 / 15, color: cs.secondary),
              ),
              const SizedBox(height: TSpace.sm),
              AreaMapCard(area: listing.areaName, time: TDate.full(listing.happenedAt)),
              const SizedBox(height: TSpace.sm),
              Row(
                children: [
                  TAvatar(initials: TAvatar.initialsOf(author.displayName), size: 44),
                  const SizedBox(width: TSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author.displayName, style: text.titleMedium!.copyWith(fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('$roleLabel$returned', style: text.bodySmall!.copyWith(fontSize: 13, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _report(context),
                    style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant, padding: const EdgeInsets.symmetric(horizontal: 8)),
                    icon: const Icon(Symbols.flag_rounded, size: 18),
                    label: const Text('Shikoyat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _report(BuildContext context) async {
    final ok = await TFeedback.confirm(
      context,
      title: 'Eʼlon ustidan shikoyat qilasizmi?',
      body: 'Moderatorlar eʼlonni koʻrib chiqadi. Shikoyatingiz anonim qoladi.',
      confirmLabel: 'Shikoyat qilish',
      destructive: true,
    );
    if (ok && context.mounted) TFeedback.success(context, 'Shikoyat yuborildi');
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.listing, required this.index});

  final Listing listing;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = context.ts;
    final count = listing.photoCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: '${listing.title}, ${index + 1}-rasm, jami $count',
          image: true,
          child: Stack(
            children: [
              PhotoPlaceholder(
                icon: listing.category.icon,
                tint: listing.tint + index,
                height: 236,
                width: double.infinity,
                iconSize: 72,
                radius: TRadius.md,
              ),
              if (count > 1)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: ts.photoChip, borderRadius: BorderRadius.circular(TRadius.xs)),
                    child: Text(
                      '${index + 1} / $count',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: TSpace.xs),
          Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: TSpace.xs),
                Semantics(
                  button: true,
                  selected: i == index,
                  label: '${i + 1}-rasm',
                  child: GestureDetector(
                    onTap: () => context.read<DetailCubit>().selectPhoto(i),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: ts.placeholder(listing.tint + i),
                        borderRadius: BorderRadius.circular(TRadius.sm),
                        border: Border.all(color: i == index ? cs.primary : cs.outlineVariant, width: i == index ? 2 : 1),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.listing, required this.isMine});

  final Listing listing;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TBottomBar(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.lock_rounded, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Telefon raqamlar yashirin. Aloqa faqat ilova ichida.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: TSpace.xs),
        if (isMine)
          TButton.primary(
            label: 'Soʻrovlarni koʻrish',
            icon: Symbols.shield_person_rounded,
            onPressed: () => context.push(Routes.claims(listing.id)),
          )
        else if (listing.isFound)
          TButton.primary(label: 'Bu meniki', onPressed: () => context.push(Routes.claim(listing.id)))
        else
          TButton.primary(
            label: 'Men topdim',
            onPressed: () => TFeedback.success(context, 'Egasiga xabar yuborildi'),
          ),
      ],
    );
  }
}
