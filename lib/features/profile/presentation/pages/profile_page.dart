import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/t_avatar.dart';
import '../../../../core/widgets/t_chip.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../../core/widgets/t_refresh_scroll_view.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/profile_summary.dart';
import '../cubit/profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<ProfileCubit>()..load(), child: const _ProfileView());
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  static const _months = [
    'Yanvar',
    'Fevral',
    'Mart',
    'Aprel',
    'May',
    'Iyun',
    'Iyul',
    'Avgust',
    'Sentyabr',
    'Oktyabr',
    'Noyabr',
    'Dekabr',
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (a, b) => b.signedOut && !a.signedOut,
      listener: (context, _) => context.go(Routes.signIn),
      builder: (context, state) => Scaffold(
        body: switch (state.view) {
          ViewLoading() || ViewEmpty() => const SafeArea(child: CardsSkeleton(count: 3)),
          ViewError(:final isOffline) => SafeArea(
            child: isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load),
          ),
          // Fixed status-bar strip; the header scrolls (and pulls) beneath it.
          ViewLoaded(:final data) => Column(
            children: [
              ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                child: SizedBox(height: MediaQuery.paddingOf(context).top, width: double.infinity),
              ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: TRefreshScrollView(
                    onRefresh: () => cubit.load(silent: true),
                    slivers: [
                      SliverList.list(
                        children: [
                          _Header(
                            p: data,
                            since: '${_months[data.memberSince.month - 1]} ${data.memberSince.year} dan beri aʼzo',
                          ),
                          _MyListings(p: data, showReturned: state.showReturned),
                          _Settings(notificationsOn: data.notificationsOn),
                          const SizedBox(height: TSpace.xl),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.p, required this.since});

  final ProfileSummary p;
  final String since;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    Widget stat(int n, String label, {bool good = false}) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: good ? tc.foundContainer : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(TRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$n',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: good ? tc.found : null),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: good ? tc.found : cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );

    return Material(
      color: cs.surfaceContainerLowest,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TSpace.screen, TSpace.lg, TSpace.screen, TSpace.md),
            child: Column(
              children: [
                Row(
                  children: [
                    TAvatar(
                      initials: TAvatar.initialsOf(p.displayName),
                      size: 64,
                      tone: AvatarTone.lost,
                      imagePath: p.avatarPath,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(since, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: 'Profilni tahrirlash',
                      style: IconButton.styleFrom(
                        side: BorderSide(color: cs.outlineVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TRadius.md)),
                        fixedSize: const Size(48, 48),
                      ),
                      onPressed: () => context.push('${Routes.profileSetup}?edit=1'),
                      icon: const Icon(Symbols.edit_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: TSpace.md),
                Row(
                  children: [
                    stat(p.total, 'Eʼlonlar'),
                    const SizedBox(width: TSpace.xs),
                    stat(p.returned.length, 'Qaytarilgan', good: true),
                    const SizedBox(width: TSpace.xs),
                    stat(p.gotBack, 'Topib olgan'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyListings extends StatelessWidget {
  const _MyListings({required this.p, required this.showReturned});

  final ProfileSummary p;
  final bool showReturned;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final items = showReturned ? p.returned : p.active;
    return Padding(
      padding: const EdgeInsets.fromLTRB(TSpace.screen, TSpace.sm, TSpace.screen, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wraps under the title on narrow screens / large text.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: TSpace.xs,
            runSpacing: TSpace.xs,
            children: [
              const Text('Mening eʼlonlarim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              TSegmented(
                items: [
                  (Symbols.radio_button_checked_rounded, 'Faol · ${p.active.length}'),
                  (Symbols.check_circle_rounded, 'Qaytarilgan · ${p.returned.length}'),
                ],
                selected: showReturned ? 1 : 0,
                onChanged: (i) => cubit.showTab(returned: i == 1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            SizedBox(
              height: 260,
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
      ),
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
              PhotoPlaceholder(icon: l.category.icon, tint: l.tint, width: 56, height: 56, iconSize: 26),
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

class _Settings extends StatelessWidget {
  const _Settings({required this.notificationsOn});

  final bool notificationsOn;

  Future<void> _language(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(TSpace.screen, 0, TSpace.screen, TSpace.xs),
            child: Text('Til', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          ListTile(
            title: const Text('Oʻzbekcha'),
            trailing: const Icon(Symbols.check_rounded),
            onTap: () => Navigator.pop(ctx),
          ),
          const ListTile(enabled: false, title: Text('Ўзбекча'), subtitle: Text('Tez orada')),
          const ListTile(enabled: false, title: Text('Русский'), subtitle: Text('Tez orada')),
        ],
      ),
    ),
  );

  Future<void> _signOut(BuildContext context) async {
    final ok = await TFeedback.confirm(
      context,
      title: 'Hisobdan chiqasizmi?',
      body: 'Eʼlonlaringiz va chatlaringiz saqlanib qoladi. Qayta kirish uchun telefon raqamingiz kerak boʻladi.',
      confirmLabel: 'Chiqish',
      cancelLabel: 'Bekor qilish',
      destructive: true,
    );
    if (ok && context.mounted) context.read<ProfileCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<ProfileCubit>();
    final divider = Divider(height: 1, color: cs.outlineVariant);

    Widget tile({required IconData icon, required String label, Widget? trailing, VoidCallback? onTap, Color? color}) =>
        InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: TSize.button),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: color ?? cs.onSurfaceVariant),
                  const SizedBox(width: TSpace.sm),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 15, color: color, fontWeight: color != null ? FontWeight.w600 : null),
                    ),
                  ),
                  // Scales down instead of overflowing with large text.
                  if (trailing != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.6),
                      child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: trailing),
                    ),
                ],
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(TSpace.screen, TSpace.md, TSpace.screen, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text('Sozlamalar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                tile(
                  icon: Symbols.language_rounded,
                  label: 'Til',
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text('Oʻzbekcha', style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
                  ),
                  onTap: () => _language(context),
                ),
                divider,
                tile(
                  icon: Symbols.contrast_rounded,
                  label: 'Mavzu',
                  trailing: BlocBuilder<ThemeCubit, ThemeMode>(
                    builder: (context, mode) => _ThemeSwitch(mode: mode, onChanged: context.read<ThemeCubit>().set),
                  ),
                ),
                divider,
                tile(
                  icon: Symbols.notifications_rounded,
                  label: 'Bildirishnomalar',
                  trailing: Switch(value: notificationsOn, onChanged: cubit.setNotifications),
                  onTap: () => cubit.setNotifications(!notificationsOn),
                ),
                divider,
                tile(icon: Symbols.logout_rounded, label: 'Chiqish', color: cs.error, onTap: () => _signOut(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSwitch extends StatelessWidget {
  const _ThemeSwitch({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  static const _options = [(ThemeMode.system, 'Tizim'), (ThemeMode.light, 'Yorugʻ'), (ThemeMode.dark, 'Qorongʻi')];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (m, label) in _options)
            Semantics(
              selected: m == mode,
              button: true,
              child: InkWell(
                onTap: () => onChanged(m),
                borderRadius: BorderRadius.circular(TRadius.sm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  constraints: const BoxConstraints(minHeight: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: m == mode ? cs.surfaceContainerLowest : Colors.transparent,
                    borderRadius: BorderRadius.circular(TRadius.sm),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: m == mode ? cs.onSurface : cs.onSurfaceVariant,
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
