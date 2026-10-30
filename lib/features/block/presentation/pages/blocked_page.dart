import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/glass_empty_icon.dart';
import '../../../../core/widgets/glass_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../domain/entities/blocked_user.dart';
import '../cubit/blocked_cubit.dart';

const _title = 'Bloklanganlar';
const _side = GlassHeader.side;

/// BL3: everyone the signed-in user has blocked, with "Blokdan chiqarish"
/// per row. Unblocking needs no confirmation — the snackbar can undo it.
class BlockedPage extends StatelessWidget {
  const BlockedPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => getIt<BlockedCubit>()..load(), child: const _BlockedView());
}

class _BlockedView extends StatefulWidget {
  const _BlockedView();

  @override
  State<_BlockedView> createState() => _BlockedViewState();
}

class _BlockedViewState extends State<_BlockedView> {
  final _offset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  Future<void> _unblock(BuildContext context, BlockedUser person) async {
    final cubit = context.read<BlockedCubit>();
    HapticFeedback.selectionClick();
    final done = await cubit.unblock(person.id);
    if (!context.mounted) return;
    if (!done) {
      TFeedback.error(context, tr('Blokdan chiqarib boʻlmadi'));
      return;
    }
    TFeedback.success(
      context,
      tr('{name} blokdan chiqarildi', {'name': person.name}),
      action: tr('Bekor qilish'),
      onAction: () => cubit.undo(person),
      duration: const Duration(seconds: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<BlockedCubit>();
    final top = GlassHeader.top(context);
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.depth == 0 && n.metrics.axis == Axis.vertical) _offset.value = n.metrics.pixels;
            return false;
          },
          child: BlocBuilder<BlockedCubit, BlockedState>(
            builder: (context, state) => CustomScrollView(
              slivers: [
                SliverPersistentHeader(pinned: true, delegate: _Bar(top: top, offset: _offset)),
                SliverToBoxAdapter(child: GlassLargeTitle(tr(_title), oneLine: true)),
                ...switch (state.view) {
                  ViewLoading() => [
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(_side, 6, _side, bottom),
                        child: const RowsSkeleton(count: 3),
                      ),
                    ),
                  ],
                  ViewEmpty() => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(padding: EdgeInsets.only(bottom: bottom), child: const _Empty()),
                    ),
                  ],
                  ViewError(:final isOffline) => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottom),
                        child: isOffline ? OfflineState(onRetry: cubit.load) : ErrorState(onRetry: cubit.load),
                      ),
                    ),
                  ],
                  ViewLoaded(:final data) => [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(_side, 0, _side, bottom),
                      sliver: SliverList.list(
                        children: [
                          _Group(
                            children: [
                              for (var i = 0; i < data.length; i++)
                                _PersonRow(
                                  person: data[i],
                                  divider: i < data.length - 1,
                                  onUnblock: () => _unblock(context, data[i]),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _Note(),
                        ],
                      ),
                    ),
                  ],
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinned glass bar: back button and the inline title.
class _Bar extends SliverPersistentHeaderDelegate {
  const _Bar({required this.top, required this.offset});

  final double top;
  final ValueListenable<double> offset;

  @override
  double get minExtent => top + GlassHeader.barHeight;

  @override
  double get maxExtent => top + GlassHeader.barHeight;

  @override
  bool shouldRebuild(covariant _Bar old) => old.top != top || old.offset != offset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return GlassBarBackground(
      offset: offset,
      hairlineAt: GlassHeader.titleExtent - 1,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(children: children),
  );
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.divider, required this.onUnblock});

  final BlockedUser person;
  final bool divider;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = person.name.trim();
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: cs.surfaceContainerHigh, shape: BoxShape.circle),
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              textScaler: TextScaler.noScaling,
              style: TextStyle(fontSize: 17, color: cs.secondary).inter(FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? tr('Foydalanuvchi') : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: cs.onSurface).inter(FontWeight.w600),
                ),
                Text(
                  tr('Bloklangan: {date}', {'date': TDate.day(person.blockedAt).toLowerCase()}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant).inter(FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _UnblockButton(onTap: onUnblock, name: name),
        ],
      ),
    );
    if (!divider) return row;
    return Column(
      children: [
        row,
        Padding(
          padding: const EdgeInsets.only(left: 70),
          child: Container(height: 0.5, color: context.ts.separator),
        ),
      ],
    );
  }
}

class _UnblockButton extends StatelessWidget {
  const _UnblockButton({required this.onTap, required this.name});

  final VoidCallback onTap;
  final String name;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${tr('Blokdan chiqarish')}, $name',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 44 tall for the finger, 34 of it drawn.
        child: SizedBox(
          height: 44,
          child: Center(
            child: Container(
              height: 34,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(999)),
              child: Text(
                tr('Blokdan chiqarish'),
                style: TextStyle(fontSize: 13, color: cs.onPrimaryContainer).inter(FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.info_rounded, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tr('Bloklangan odamlar sizga yoza olmaydi va soʻrov yubora olmaydi. Ularning eʼlonlari sizga koʻrinmaydi.'),
              style: TextStyle(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant).inter(FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

/// BL4.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GlassEmptyIcon(icon: Symbols.block_rounded, badge: GlassIconBadge.none),
          const SizedBox(height: 18),
          Text(
            tr('Hech kim bloklanmagan'),
            textAlign: TextAlign.center,
            style: text.headlineSmall!.copyWith(color: cs.onSurface).inter(FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Chat yoki eʼlon menyusidagi “Bloklash” orqali qoʻshiladi.'),
            textAlign: TextAlign.center,
            style: text.bodyLarge!.copyWith(fontSize: 15, height: 21 / 15, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
