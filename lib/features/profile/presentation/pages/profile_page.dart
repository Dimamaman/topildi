import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/pull_down_menu.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_avatar.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../../core/widgets/t_refresh_scroll_view.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/profile_summary.dart';
import '../cubit/profile_cubit.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/l10n/app_language.dart';
import '../../../../core/l10n/language_cubit.dart';
import '../../../../core/widgets/avatar_tone.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<ProfileCubit>()..load(), child: const _ProfileView());
  }
}

const _side = 16.0;

/// Profil, iOS 26 style. One scroll view: a tinted header card with glass
/// stat tiles, a horizontal row of own listings and an inset settings group;
/// the shell's glass tab bar and "+" float over it.
class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<ProfileCubit>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (a, b) => b.signedOut && !a.signedOut,
        listener: (context, _) => context.go(Routes.signIn),
        builder: (context, state) => Scaffold(
          body: switch (state.view) {
            ViewLoading() || ViewEmpty() => const _ProfileSkeleton(),
            ViewError(:final isOffline) => SafeArea(
              child: isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load),
            ),
            ViewLoaded(:final data) => TRefreshScrollView(
              onRefresh: () => cubit.load(silent: true),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  sliver: SliverToBoxAdapter(
                    child: _Header(p: data, since: TDate.memberSince(data.memberSince)),
                  ),
                ),
                SliverToBoxAdapter(child: _MyListings(p: data)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    _side,
                    0,
                    _side,
                    math.max(120, MediaQuery.paddingOf(context).bottom + 24),
                  ),
                  sliver: SliverToBoxAdapter(child: _Settings(notificationsOn: data.notificationsOn)),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

/// Tappable area with no ripple or highlight.
class _Tap extends StatelessWidget {
  const _Tap({required this.label, required this.onTap, required this.child});

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: child),
  );
}

/// Inset card on primary-container: edit button, avatar + name, three glass stat tiles.
class _Header extends StatelessWidget {
  const _Header({required this.p, required this.since});

  final ProfileSummary p;
  final String since;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    // Own profile: first name only (the public "Ism F." form drops here).
    final name = p.displayName.trim().split(RegExp(r'\s+')).first;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 46, 16, 16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(48), bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _Tap(
              label: tr('Profilni tahrirlash'),
              onTap: () => context.push('${Routes.profileSetup}?edit=1'),
              child: SizedBox.square(
                dimension: 44,
                child: GlassSurface(child: Icon(Symbols.edit_rounded, size: 22, color: cs.onSurface)),
              ),
            ),
          ),
          // Avatar row sits 8 above the usual 16 gap.
          const SizedBox(height: 8),
          Row(
            children: [
              _Avatar(name: name, imagePath: p.avatarPath, tone: p.avatarTone, emoji: p.avatarEmoji),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.headlineMedium!
                            .copyWith(fontSize: 28, height: 34 / 28, letterSpacing: -0.5)
                            .inter(FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      since,
                      style: text.bodyMedium!
                          .copyWith(fontSize: 14, height: 20 / 14, color: cs.onPrimaryContainer)
                          .inter(FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Equal heights even when one label scales down more than the others.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Stat(n: p.total, label: tr('Eʼlonlar')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(n: p.returned.length, label: tr('Qaytarilgan'), color: tc.found),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(n: p.gotBack, label: tr('Topib olgan')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 76×76 circle inside a 3px white ring: photo, or the initial in lost colours.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imagePath, this.tone = 0, this.emoji});

  final String name;
  final String? imagePath, emoji;
  final int tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = avatarToneColors(context, tone);
    final initial = Text(
      emoji ?? TAvatar.initialsOf(name),
      textScaler: TextScaler.noScaling,
      style: Theme.of(context).textTheme.headlineSmall!
          .copyWith(fontSize: emoji != null ? 40 : 32, height: 1, color: fg)
          .inter(FontWeight.w600),
    );
    final path = imagePath;
    // 76 + the 3px ring on each side.
    return Container(
      width: 82,
      height: 82,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: cs.surfaceContainerLowest, width: 3),
      ),
      child: path != null && path.startsWith('/')
          ? Image.file(File(path), width: 76, height: 76, fit: BoxFit.cover, errorBuilder: (_, _, _) => initial)
          : initial,
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.n, required this.label, this.color});

  final int n;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$n $label',
      excludeSemantics: true,
      child: GlassSurface(
        radius: 22,
        color: context.glass.tile,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        // Scales down instead of wrapping on narrow screens / large text.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$n',
                style: text.titleLarge!
                    .copyWith(fontSize: 22, height: 28 / 22, color: color ?? cs.onSurface)
                    .inter(FontWeight.w700),
              ),
              Text(
                label,
                maxLines: 1,
                style: text.bodySmall!
                    .copyWith(fontSize: 13, height: 18 / 13, color: cs.secondary)
                    .inter(FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section title row (20/w700) with an optional trailing link.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.padding, this.trailing});

  final String title;
  final EdgeInsets padding;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge!
                    .copyWith(fontSize: 20, height: 25 / 20, letterSpacing: -0.2)
                    .inter(FontWeight.w700),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _MyListings extends StatelessWidget {
  const _MyListings({required this.p});

  final ProfileSummary p;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [...p.active, ...p.returned];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          tr('Mening eʼlonlarim'),
          padding: const EdgeInsets.fromLTRB(_side + 4, 20, _side + 4, 10),
          trailing: items.isEmpty
              ? null
              : _Tap(
                  label: tr('Hammasi'),
                  onTap: () => context.push(Routes.myListings),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        tr('Hammasi'),
                        style: Theme.of(context).textTheme.bodyLarge!
                            .copyWith(fontSize: 16, height: 21 / 16, color: cs.primary)
                            .inter(FontWeight.w400),
                      ),
                    ),
                  ),
                ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: _side),
            child: _NoListings(),
          )
        else
          // A Row (not a fixed-height ListView) so the cards grow with the text size.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _side),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  _MineCard(m: items[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// 236-wide card: 104 photo with a glass status tag, title, type · area.
class _MineCard extends StatelessWidget {
  const _MineCard({required this.m});

  final MyListing m;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    final l = m.listing;
    final returned = l.status == ListingStatus.returned;
    final (tagLabel, tagBg, tagFg) = returned
        ? (tr('Qaytarildi'), tc.successContainer, tc.success)
        : m.pendingClaims > 0
        ? (
            tr('Soʻrov bor · {pendingClaims}', {'pendingClaims': m.pendingClaims}),
            tc.warningContainer.withValues(alpha: 0.9),
            tc.warning,
          )
        : (tr('Faol'), cs.primaryContainer.withValues(alpha: 0.9), cs.onPrimaryContainer);
    final type = l.isFound ? tr('Topilgan') : tr('Yoʻqolgan');
    final area = l.areaName.split(',').first;
    return _Tap(
      label: '${l.title}, $type, $area, $tagLabel',
      onTap: () => context.push(Routes.listing(l.id)),
      child: Container(
        width: 236,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(26)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 104,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoPlaceholder(
                    icon: l.category.icon,
                    tint: l.tint,
                    iconSize: 48,
                    radius: 0,
                    width: 236,
                    height: 104,
                    path: l.photoAt(0),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: SizedBox(
                      height: 28,
                      child: GlassSurface(
                        color: tagBg,
                        shadow: false,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            tagLabel,
                            textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
                            style: text.labelMedium!
                                .copyWith(fontSize: 12, height: 16 / 12, letterSpacing: 0, color: tagFg)
                                .inter(FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium!.copyWith(fontSize: 16, height: 21 / 16).inter(FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: type,
                          style: text.bodySmall!
                              .copyWith(fontSize: 13, height: 18 / 13, color: l.isFound ? tc.found : tc.lost)
                              .inter(FontWeight.w600),
                        ),
                        TextSpan(text: ' · $area'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall!
                        .copyWith(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant)
                        .inter(FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoListings extends StatelessWidget {
  const _NoListings();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(26)),
      child: Column(
        children: [
          Icon(Symbols.inventory_2_rounded, size: 40, weight: 300, color: context.ts.placeholderIcon),
          const SizedBox(height: 10),
          Text(
            tr('Hali eʼlon bermagansiz'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 16).inter(FontWeight.w600),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TRadius.full)),
              overlayColor: Colors.transparent,
            ),
            onPressed: () => context.push(Routes.create),
            child: Text(tr('Eʼlon berish')),
          ),
        ],
      ),
    );
  }
}

class _Settings extends StatelessWidget {
  const _Settings({required this.notificationsOn});

  final bool notificationsOn;

  static const _themes = [(ThemeMode.system, 'Tizim'), (ThemeMode.light, 'Yorugʻ'), (ThemeMode.dark, 'Qorongʻi')];

  /// Glass pull-down with the three interface languages, each named in itself.
  Future<void> _language(BuildContext context, BuildContext anchor, AppLanguage current) async {
    final cubit = context.read<LanguageCubit>();
    final picked = await showPullDownMenu(
      context,
      anchor: anchor,
      label: tr('Til'),
      items: [for (final l in AppLanguage.values) (l, l.nativeName)],
      current: current,
    );
    if (picked != null) cubit.set(picked);
  }

  /// Pull-down menu anchored under the row's trailing value.
  Future<void> _theme(BuildContext context, BuildContext anchor, ThemeMode current) async {
    final themeCubit = context.read<ThemeCubit>();
    final picked = await showPullDownMenu(
      context,
      anchor: anchor,
      items: [for (final (m, l) in _themes) (m, tr(l))],
      current: current,
    );
    if (picked != null) themeCubit.set(picked);
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await TFeedback.confirm(
      context,
      title: tr('Hisobdan chiqasizmi?'),
      body: tr('Eʼlonlaringiz va chatlaringiz saqlanib qoladi. Qayta kirish uchun telefon raqamingiz kerak boʻladi.'),
      confirmLabel: tr('Chiqish'),
      cancelLabel: tr('Bekor qilish'),
      destructive: true,
    );
    if (ok && context.mounted) context.read<ProfileCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final cubit = context.read<ProfileCubit>();
    final body = Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 16, height: 22 / 16).inter(FontWeight.w400);
    // Starts under the label, not under the icon: 16 + 22 + 12.
    final separator = Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Container(height: 0.5, color: context.ts.separator),
    );

    Widget row({required IconData icon, required String label, required Widget trailing}) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: body)),
            const SizedBox(width: 8),
            // Scales down instead of overflowing with large text.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.45),
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: trailing),
            ),
          ],
        ),
      ),
    );

    Widget value(String text, IconData icon) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: body.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(width: 4),
        Icon(icon, size: 20, color: cs.onSurfaceVariant),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(tr('Sozlamalar'), padding: EdgeInsets.fromLTRB(4, 22, 4, 10)),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(26)),
          child: Column(
            children: [
              BlocBuilder<LanguageCubit, AppLanguage>(
                builder: (context, language) => Builder(
                  builder: (anchor) => _Tap(
                    label: '${tr('Til')}, ${language.nativeName}',
                    onTap: () => _language(context, anchor, language),
                    child: row(
                      icon: Symbols.language_rounded,
                      label: tr('Til'),
                      trailing: value(language.nativeName, Symbols.unfold_more_rounded),
                    ),
                  ),
                ),
              ),
              separator,
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, mode) {
                  final label = tr(_themes.firstWhere((t) => t.$1 == mode).$2);
                  return Builder(
                    builder: (anchor) => _Tap(
                      label: tr('Mavzu, {label}', {'label': label}),
                      onTap: () => _theme(context, anchor, mode),
                      child: row(
                        icon: Symbols.contrast_rounded,
                        label: tr('Mavzu'),
                        trailing: value(label, Symbols.unfold_more_rounded),
                      ),
                    ),
                  );
                },
              ),
              separator,
              Semantics(
                toggled: notificationsOn,
                label: tr('Bildirishnomalar'),
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => cubit.setNotifications(!notificationsOn),
                  behavior: HitTestBehavior.opaque,
                  child: row(
                    icon: Symbols.notifications_rounded,
                    label: tr('Bildirishnomalar'),
                    trailing: CupertinoSwitch(
                      value: notificationsOn,
                      activeTrackColor: tc.success,
                      onChanged: cubit.setNotifications,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Tap(
          label: tr('Chiqish'),
          onTap: () => _signOut(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(26)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.logout_rounded, size: 20, color: cs.error),
                const SizedBox(width: 8),
                Text(tr('Chiqish'), style: body.copyWith(color: cs.error).inter(FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Loading placeholder in the shape of the loaded page: tinted header with
/// avatar and three stat tiles, the horizontal "Mening eʼlonlarim" cards
/// and the settings group — so nothing jumps when the data arrives.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = context.ts;
    final g = context.glass;
    Widget bar(double w, double h, Color c, {double r = TRadius.xs}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)),
    );
    Widget card() => Container(
      width: 236,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(26)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 104, color: ts.skeleton),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bar(150, 16, ts.skeleton), const SizedBox(height: 8), bar(110, 12, ts.skeletonSoft)],
            ),
          ),
        ],
      ),
    );
    Widget settingsRow() => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          bar(22, 22, ts.skeleton, r: 11),
          const SizedBox(width: 12),
          bar(110, 14, ts.skeleton),
          const Spacer(),
          bar(70, 14, ts.skeletonSoft),
        ],
      ),
    );
    return Semantics(
      label: tr('Yuklanmoqda'),
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 46, 16, 16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(48), bottom: Radius.circular(36)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.centerRight, child: bar(44, 44, g.tile, r: 22)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        bar(82, 82, g.tile, r: 41),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [bar(130, 26, g.tile), const SizedBox(height: 10), bar(180, 14, g.tile)],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: bar(double.infinity, 68, g.tile, r: 22)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_side + 4, 24, _side + 4, 12),
              child: Row(children: [bar(170, 20, ts.skeleton), const Spacer(), bar(64, 16, ts.skeletonSoft)]),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: _side),
              child: Row(children: [card(), const SizedBox(width: 12), card()]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_side + 4, 26, _side + 4, 12),
              child: Align(alignment: Alignment.centerLeft, child: bar(130, 20, ts.skeleton)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _side),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(26)),
                child: Column(children: [settingsRow(), settingsRow(), settingsRow()]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
