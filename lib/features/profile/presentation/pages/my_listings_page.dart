import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/t_chip.dart';
import '../../../../core/widgets/t_top_bar.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/profile_summary.dart';
import '../cubit/profile_cubit.dart';

/// "Mening eʼlonlarim" — every own listing with a Faol / Qaytarilgan filter.
/// Opened from "Hammasi" on the Profil page.
class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<ProfileCubit>()..load(), child: const _MyListingsView());
  }
}

class _MyListingsView extends StatelessWidget {
  const _MyListingsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    return Scaffold(
      appBar: const TTopBar(title: 'Mening eʼlonlarim'),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => switch (state.view) {
          ViewLoading() || ViewEmpty() => const CardsSkeleton(count: 3),
          ViewError(:final isOffline) =>
            isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load),
          ViewLoaded(:final data) => _List(p: data, showReturned: state.showReturned),
        },
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.p, required this.showReturned});

  final ProfileSummary p;
  final bool showReturned;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final items = showReturned ? p.returned : p.active;
    return ListView(
      padding: EdgeInsets.fromLTRB(TSpace.screen, TSpace.xs, TSpace.screen, MediaQuery.paddingOf(context).bottom + 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TSegmented(
            items: [
              (Symbols.radio_button_checked_rounded, 'Faol · ${p.active.length}'),
              (Symbols.check_circle_rounded, 'Qaytarilgan · ${p.returned.length}'),
            ],
            selected: showReturned ? 1 : 0,
            onChanged: (i) => cubit.showTab(returned: i == 1),
          ),
        ),
        const SizedBox(height: TSpace.sm),
        if (items.isEmpty)
          SizedBox(
            height: 300,
            child: EmptyState(
              icon: Symbols.search_rounded,
              title: showReturned ? 'Hali qaytarilgan buyum yoʻq' : 'Sizda eʼlon yoʻq',
              body: showReturned
                  ? 'Buyumni egasiga topshirganingizda shu yerda koʻrinadi.'
                  : 'Nimadir topdingizmi yoki yoʻqotdingizmi? Bir daqiqada eʼlon bering.',
              cta: showReturned ? null : 'Eʼlon berish',
              onCta: () => context.push(Routes.create),
            ),
          )
        else
          for (final m in items) ...[_MineRow(m: m), const SizedBox(height: 10)],
      ],
    );
  }
}

class _MineRow extends StatelessWidget {
  const _MineRow({required this.m});

  final MyListing m;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = m.listing;
    final type = l.isFound ? 'Topilgan' : 'Yoʻqolgan';
    final returned = l.status == ListingStatus.returned;
    final extra = returned
        ? 'qaytarildi'
        : m.pendingClaims > 0
        ? '${m.pendingClaims} ta soʻrov'
        : l.areaName.split(',').first;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(m.pendingClaims > 0 ? Routes.claims(l.id) : Routes.listing(l.id)),
        child: Padding(
          padding: const EdgeInsets.all(TSpace.xs),
          child: Row(
            children: [
              PhotoPlaceholder(
                icon: l.category.icon,
                tint: l.tint,
                width: 56,
                height: 56,
                iconSize: 26,
                path: l.photoAt(0),
              ),
              const SizedBox(width: TSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('$type · $extra', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: TSpace.xs),
              StatusBadge(
                kind: returned ? StatusKind.returned : (m.pendingClaims > 0 ? StatusKind.pending : StatusKind.active),
                label: !returned && m.pendingClaims > 0 ? 'Soʻrov bor' : null,
                size: BadgeSize.small,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
