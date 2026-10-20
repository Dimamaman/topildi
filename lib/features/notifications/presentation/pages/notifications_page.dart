import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<NotificationsCubit>()..load(), child: const _NotificationsView());
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<NotificationsCubit>();
    return BlocBuilder<NotificationsCubit, ViewState<List<AppNotification>>>(
      builder: (context, state) {
        final hasUnread = state is ViewLoaded<List<AppNotification>> && state.data.any((n) => !n.read);
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(65),
            child: Material(
              color: cs.surfaceContainerLowest,
              child: Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant))),
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 64,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Orqaga',
                            icon: const Icon(Symbols.arrow_back_rounded),
                            onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text('Bildirishnomalar',
                                overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          ),
                          if (hasUnread) TextButton(onPressed: cubit.markAllRead, child: const Text('Oʻqildi')),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: switch (state) {
            ViewLoading() => const RowsSkeleton(),
            ViewEmpty() => EmptyState(
                icon: Symbols.notifications_rounded,
                title: 'Yangi xabar yoʻq',
                body: 'Mos eʼlon yoki yangi soʻrov chiqsa, shu yerda koʻrasiz.',
                cta: 'Sozlamalar',
                onCta: () => context.go(Routes.profile),
              ),
            ViewError(:final isOffline) => isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load),
            ViewLoaded(:final data) => RefreshIndicator(
                onRefresh: () => cubit.load(silent: true),
                child: ListView(children: _grouped(context, data)),
              ),
          },
        );
      },
    );
  }

  List<Widget> _grouped(BuildContext context, List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groups = <String, List<AppNotification>>{'Bugun': [], 'Shu hafta': [], 'Oldinroq': []};
    for (final n in items) {
      final d = n.createdAt;
      final key = !d.isBefore(today) ? 'Bugun' : (today.difference(d).inDays < 7 ? 'Shu hafta' : 'Oldinroq');
      groups[key]!.add(n);
    }
    final cs = Theme.of(context).colorScheme;
    return [
      for (final g in groups.entries)
        if (g.value.isNotEmpty) ...[
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TSpace.screen, TSpace.md, TSpace.screen, 6),
              child: Text(g.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            ),
          ),
          for (final n in g.value) _Row(n: n),
        ],
      const SizedBox(height: TSpace.lg),
    ];
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.n});

  final AppNotification n;

  String _time(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Hozirgina';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
    if (diff.inHours < 24 && DateTime.now().day == d.day) return '${diff.inHours} soat oldin';
    return TDate.relative(d, withTimeForOld: false);
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
      case OpenProfile():
        context.go(Routes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final (icon, bg, fg) = switch (n.kind) {
      NotificationKind.newClaim => (Symbols.shield_person_rounded, cs.primaryContainer, cs.onPrimaryContainer),
      NotificationKind.message => (Symbols.chat_bubble_rounded, cs.primaryContainer, cs.onPrimaryContainer),
      NotificationKind.match => (Symbols.search_rounded, tc.lostContainer, tc.lost),
      NotificationKind.claimAccepted => (Symbols.check_rounded, tc.foundContainer, tc.found),
      NotificationKind.returned => (Symbols.favorite_rounded, tc.foundContainer, tc.found),
      NotificationKind.expiring => (Symbols.schedule_rounded, tc.warningContainer, tc.warning),
    };
    final unread = !n.read;
    return Semantics(
      label: unread ? 'Yangi' : null,
      child: Material(
        color: unread ? context.ts.primaryTint : Colors.transparent,
        child: InkWell(
          onTap: () => _go(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: TSpace.screen, vertical: TSpace.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: fg),
                ),
                const SizedBox(width: TSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.text,
                          style: TextStyle(fontSize: 15, height: 21 / 15, fontWeight: unread ? FontWeight.w600 : FontWeight.w400)),
                      const SizedBox(height: 4),
                      Text(_time(n.createdAt), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: TSpace.xs),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: unread ? cs.primary : Colors.transparent, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
