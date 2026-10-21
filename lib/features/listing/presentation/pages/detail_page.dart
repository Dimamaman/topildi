import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/view_state.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../domain/entities/listing.dart';
import '../category_ui.dart';
import '../cubit/detail_cubit.dart';
import '../widgets/area_map_page.dart';
import '../widgets/photo_viewer.dart';

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

const _side = 16.0;
const _barHeight = 44.0;

/// Gap between the top bar's buttons and the carousel.
const _barGap = 14.0;

/// Eʼlon detail, iOS 26 style. One scroll view: glass buttons pinned at the
/// top (their backdrop turns to blurred glass once content scrolls under
/// them), photo carousel, title, details group; a glass action panel floats
/// at the bottom. A visitor sees "Bu meniki"; the author sees claims,
/// "Qaytarildi", edit and delete.
class _DetailView extends StatefulWidget {
  const _DetailView({required this.listingId});

  final String listingId;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final _offset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  void _close() => context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<DetailCubit>();
    final top = MediaQuery.paddingOf(context).top;
    final barTop = top < 30 ? top + 8 : top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: BlocConsumer<DetailCubit, DetailState>(
        listenWhen: (a, b) => b.deleted && !a.deleted,
        listener: (context, _) {
          TFeedback.success(context, 'Eʼlon oʻchirildi');
          _close();
        },
        builder: (context, state) {
          final view = state.view;
          final listing = view is ViewLoaded<Listing> ? view.data : null;
          final bar = _TopBar(
            top: barTop,
            offset: _offset,
            title: state.isMine ? 'Mening eʼlonim' : 'Eʼlon',
            onBack: _close,
            trailing: listing == null
                ? null
                : state.isMine
                ? _AuthorActions(listing: listing)
                : _GlassButton(
                    icon: Symbols.ios_share_rounded,
                    iconSize: 22,
                    label: 'Ulashish',
                    onTap: () => _share(context, listing),
                  ),
          );
          return Scaffold(
            body: switch (view) {
              ViewLoading() || ViewEmpty() => _Scaffold(bar: bar, children: const [_Skeleton()]),
              ViewError(:final failure, :final isOffline) => _Scaffold(
                bar: bar,
                fill: true,
                children: [
                  if (isOffline)
                    _OfflineBanner(onRetry: () => cubit.load(widget.listingId))
                  else if (failure is NotFoundFailure)
                    EmptyState(
                      icon: Symbols.search_off_rounded,
                      title: 'Eʼlon topilmadi',
                      body: 'Bu eʼlon oʻchirilgan yoki yopilgan boʻlishi mumkin.',
                      cta: 'Lentaga qaytish',
                      onCta: () => context.go(Routes.home),
                    )
                  else
                    MessageState(
                      icon: Symbols.error_rounded,
                      title: 'Eʼlon yuklanmadi',
                      body: 'Birozdan soʻng qayta urinib koʻring.',
                      cta: 'Qayta urinish',
                      onCta: () => cubit.load(widget.listingId),
                      circle: Theme.of(context).colorScheme.errorContainer,
                      fg: Theme.of(context).colorScheme.error,
                    ),
                ],
              ),
              ViewLoaded(:final data) => Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.depth == 0 && n.metrics.axis == Axis.vertical) _offset.value = n.metrics.pixels;
                      return false;
                    },
                    child: _Scaffold(
                      bar: bar,
                      children: [
                        _Carousel(listing: data, index: state.photoIndex, isMine: state.isMine),
                        _Heading(listing: data, showDescription: !state.isMine),
                        if (state.isMine && state.pendingClaims > 0)
                          _ClaimsCard(count: state.pendingClaims, onTap: () => _openClaims(context, data)),
                        _Details(listing: data, showMap: !state.isMine),
                        SizedBox(
                          // The panel grows with the text size; keep the last row clear of it.
                          height:
                              MediaQuery.textScalerOf(
                                context,
                              ).scale(state.isMine ? _AuthorPanel.height : _VisitorPanel.height) +
                              18,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: math.max(20, MediaQuery.paddingOf(context).bottom - 14),
                    child: state.isMine
                        ? _AuthorPanel(listing: data, pending: state.pendingClaims, busy: state.busy)
                        : _VisitorPanel(listing: data, claimSent: state.claimSent),
                  ),
                ],
              ),
            },
          );
        },
      ),
    );
  }
}

Future<void> _share(BuildContext context, Listing l) async {
  final box = context.findRenderObject() as RenderBox?;
  final type = l.isFound ? 'Topilgan' : 'Yoʻqolgan';
  try {
    await SharePlus.instance.share(
      ShareParams(
        subject: l.title,
        text: '$type: ${l.title}\n${l.areaName}\n\nTopildi ilovasida koʻring.',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } on Exception {
    if (context.mounted) TFeedback.error(context, 'Ulashib boʻlmadi');
  }
}

Future<void> _openClaims(BuildContext context, Listing l) async {
  final cubit = context.read<DetailCubit>();
  await context.push(Routes.claims(l.id));
  await cubit.refreshClaims();
}

/// CustomScrollView with the pinned glass bar and padded content.
class _Scaffold extends StatelessWidget {
  const _Scaffold({required this.bar, required this.children, this.fill = false});

  final _TopBar bar;
  final List<Widget> children;

  /// Centre a single state view in the remaining space.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: Theme.of(context).platform == TargetPlatform.iOS
          ? const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())
          : const ClampingScrollPhysics(),
      slivers: [
        SliverPersistentHeader(pinned: true, delegate: bar),
        if (fill)
          SliverFillRemaining(hasScrollBody: false, child: Column(children: children))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(_side, _barGap, _side, 0),
            sliver: SliverList.list(children: children),
          ),
      ],
    );
  }
}

/// Back · title · trailing. Transparent at rest; blurred glass page
/// background with a hairline once content scrolls beneath.
class _TopBar extends SliverPersistentHeaderDelegate {
  const _TopBar({required this.top, required this.offset, required this.title, required this.onBack, this.trailing});

  final double top;
  final ValueListenable<double> offset;
  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  double get minExtent => top + _barHeight;

  @override
  double get maxExtent => top + _barHeight;

  @override
  bool shouldRebuild(covariant _TopBar old) =>
      old.top != top || old.offset != offset || old.title != title || old.trailing != trailing;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Extends below the bar so the buttons' gap is glass too.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: -8,
          child: ValueListenableBuilder<double>(
            valueListenable: offset,
            builder: (context, o, _) => AnimatedOpacity(
              opacity: o > 1 ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.86),
                      border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(_side, top, _side, 0),
          child: Row(
            children: [
              _GlassButton(icon: Symbols.chevron_left_rounded, label: 'Orqaga', onTap: onBack),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
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
              // Keeps the title centred while the trailing loads.
              trailing ?? const SizedBox(width: 44),
            ],
          ),
        ),
      ],
    );
  }
}

/// No ripple; [label] is the accessible name.
class _Tap extends StatelessWidget {
  const _Tap({required this.label, required this.onTap, required this.child});

  final String label;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: child),
  );
}

/// 44×44 glass circle.
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.label, required this.onTap, this.iconSize = 24});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return _Tap(
      label: label,
      onTap: onTap,
      child: SizedBox.square(
        dimension: _barHeight,
        child: GlassSurface(
          child: Icon(icon, size: iconSize, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}

/// Author: one glass capsule with Tahrirlash and Yana (delete / share).
class _AuthorActions extends StatelessWidget {
  const _AuthorActions({required this.listing});

  final Listing listing;

  Future<void> _more(BuildContext context, BuildContext anchor) async {
    final cs = Theme.of(context).colorScheme;
    final box = anchor.findRenderObject()! as RenderBox;
    final overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final rect = Rect.fromPoints(
      box.localToGlobal(box.size.bottomLeft(Offset.zero), ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    PopupMenuItem<String> item(String value, IconData icon, String label, Color color) => PopupMenuItem(
      value: value,
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 16, color: color)),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: color),
        ],
      ),
    );
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
      color: cs.surfaceContainerLowest,
      elevation: 8,
      constraints: const BoxConstraints(minWidth: 220),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        item('delete', Symbols.delete_rounded, 'Eʼlonni oʻchirish', cs.error),
        item('share', Symbols.ios_share_rounded, 'Ulashish', cs.onSurface),
      ],
    );
    if (!context.mounted) return;
    switch (picked) {
      case 'delete':
        await _delete(context);
      case 'share':
        await _share(context, listing);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<DetailCubit>();
    final ok = await TFeedback.confirm(
      context,
      title: 'Eʼlonni oʻchirasizmi?',
      body: 'Eʼlon lentadan va xaritadan olib tashlanadi. Buni qaytarib boʻlmaydi.',
      confirmLabel: 'Oʻchirish',
      cancelLabel: 'Bekor qilish',
      destructive: true,
    );
    if (!ok) return;
    final f = await cubit.delete();
    if (f != null && context.mounted) TFeedback.error(context, 'Eʼlonni oʻchirib boʻlmadi');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget button(IconData icon, String label, void Function(BuildContext anchor) onTap) => Builder(
      builder: (anchor) => _Tap(
        label: label,
        onTap: () => onTap(anchor),
        child: SizedBox(
          width: 40,
          height: _barHeight,
          child: Icon(icon, size: 22, color: cs.onSurface),
        ),
      ),
    );
    return SizedBox(
      height: _barHeight,
      child: GlassSurface(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(
              Symbols.edit_rounded,
              'Tahrirlash',
              (_) => TFeedback.success(context, 'Eʼlonni tahrirlash tez orada qoʻshiladi'),
            ),
            button(Symbols.more_horiz_rounded, 'Yana', (anchor) => _more(context, anchor)),
          ],
        ),
      ),
    );
  }
}

/// Glass tag laid over the photo: height [height], pill, 13/w600.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.fg, this.bg, this.dot = false, this.height = 30});

  final String label;
  final Color fg;
  final Color? bg;
  final bool dot;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: GlassSurface(
        color: bg ?? context.glass.tag,
        shadow: false,
        padding: EdgeInsets.symmetric(horizontal: height == 30 ? 12 : 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
              style: Theme.of(context).textTheme.labelMedium!
                  .copyWith(fontSize: 13, height: 16 / 13, letterSpacing: 0, color: fg)
                  .inter(FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _Carousel extends StatefulWidget {
  const _Carousel({required this.listing, required this.index, required this.isMine});

  final Listing listing;
  final int index;
  final bool isMine;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  late final _controller = PageController(initialPage: widget.index);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int i) {
    context.read<DetailCubit>().selectPhoto(i);
    if (_controller.hasClients) {
      _controller.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
    }
  }

  Future<void> _view(int count) async {
    final i = await PhotoViewer.open(context, listing: widget.listing, count: count, initial: widget.index);
    if (i != null && i != widget.index && mounted) {
      context.read<DetailCubit>().selectPhoto(i);
      if (_controller.hasClients) _controller.jumpToPage(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final l = widget.listing;
    final count = math.max(1, l.galleryCount);
    final height = widget.isMine ? 220.0 : 244.0;
    final thumb = widget.isMine ? 56.0 : 60.0;
    final returned = l.status == ListingStatus.returned;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: count,
                  onPageChanged: context.read<DetailCubit>().selectPhoto,
                  itemBuilder: (context, i) => _Tap(
                    label: '${l.title}, ${i + 1}-rasm, jami $count. Kattalashtirish',
                    onTap: () => _view(count),
                    child: PhotoPlaceholder(
                      icon: l.category.icon,
                      tint: l.tint + i,
                      path: l.photoAt(i),
                      width: double.infinity,
                      height: height,
                      iconSize: 80,
                      radius: 0,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  right: 12,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Tag(label: l.isFound ? 'Topilgan' : 'Yoʻqolgan', fg: l.isFound ? tc.found : tc.lost, dot: true),
                      if (widget.isMine)
                        returned
                            ? _Tag(label: 'Qaytarildi', fg: tc.success, bg: tc.successContainer)
                            : _Tag(
                                label: 'Faol',
                                fg: cs.onPrimaryContainer,
                                bg: cs.primaryContainer.withValues(alpha: 0.85),
                              ),
                    ],
                  ),
                ),
                if (count > 1)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: ExcludeSemantics(
                      child: _Tag(label: '${widget.index + 1} / $count', fg: cs.onSurface, height: 28),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < count; i++)
                Semantics(
                  selected: i == widget.index,
                  child: _Tap(
                    label: '${i + 1}-rasm',
                    onTap: () => _go(i),
                    child: Container(
                      width: thumb,
                      height: thumb,
                      foregroundDecoration: i == widget.index
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: cs.primary, width: 2),
                            )
                          : null,
                      child: PhotoPlaceholder(
                        icon: l.category.icon,
                        tint: l.tint + i,
                        path: l.photoAt(i),
                        width: thumb,
                        height: thumb,
                        iconSize: 22,
                        radius: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.listing, required this.showDescription});

  final Listing listing;
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            listing.category.label,
            style: text.bodySmall!
                .copyWith(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant)
                .inter(FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Semantics(
            header: true,
            child: Text(
              listing.title,
              style: text.headlineSmall!
                  .copyWith(fontSize: 26, height: 32 / 26, letterSpacing: -0.4)
                  .inter(FontWeight.w700),
            ),
          ),
          if (showDescription && listing.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              listing.description,
              style: text.bodyLarge!
                  .copyWith(fontSize: 16, height: 23 / 16, color: cs.secondary)
                  .inter(FontWeight.w400),
            ),
          ],
        ],
      ),
    );
  }
}

/// Author: "N ta yangi soʻrov" on warning-container; opens Claims.
class _ClaimsCard extends StatelessWidget {
  const _ClaimsCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  static const _words = ['Bir', 'Ikki', 'Uch', 'Toʻrt', 'Besh', 'Olti', 'Yetti', 'Sakkiz', 'Toʻqqiz', 'Oʻn'];

  /// "Ikki kishi bu buyum ularniki ekanini aytmoqda." (words up to ten).
  static String body(int n) {
    final who = n <= 10 ? _words[n - 1] : '$n';
    return n == 1 ? '$who kishi bu buyum uniki ekanini aytmoqda.' : '$who kishi bu buyum ularniki ekanini aytmoqda.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    final title = '$count ta yangi soʻrov';
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: _Tap(
        label: '$title. ${body(count)}',
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: tc.warningContainer, borderRadius: BorderRadius.circular(26)),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: tc.warning, shape: BoxShape.circle),
                child: Icon(Symbols.inbox_rounded, size: 20, fill: 1, color: cs.surfaceContainerLowest),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium!
                          .copyWith(fontSize: 15, height: 20 / 15, color: tc.warning)
                          .inter(FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body(count),
                      style: text.bodySmall!
                          .copyWith(fontSize: 13, height: 18 / 13, color: cs.secondary)
                          .inter(FontWeight.w400),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Symbols.chevron_right_rounded, size: 22, color: tc.warning),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inset group: Joy, Topilgan/Yoʻqolgan vaqt and (visitor) Xaritada.
class _Details extends StatelessWidget {
  const _Details({required this.listing, required this.showMap});

  final Listing listing;
  final bool showMap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final label = text.bodyMedium!
        .copyWith(fontSize: 15, height: 20 / 15, color: cs.onSurfaceVariant)
        .inter(FontWeight.w400);
    final value = text.bodyMedium!.copyWith(fontSize: 15, height: 20 / 15, color: cs.onSurface).inter(FontWeight.w600);
    // Starts after the icon: 16 + 22 + 12.
    final separator = Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Container(height: 0.5, color: context.ts.separator),
    );

    Widget row(IconData icon, String name, String v, {bool chevron = false}) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 13, chevron ? 12 : 16, 13),
        child: Row(
          children: [
            Icon(icon, size: 22, color: cs.primary),
            const SizedBox(width: 12),
            Text(name, style: label),
            const SizedBox(width: 12),
            Expanded(
              child: Text(v, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis, style: value),
            ),
            if (chevron) ...[
              const SizedBox(width: 4),
              Icon(Symbols.chevron_right_rounded, size: 22, color: cs.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );

    final time = listing.isFound ? 'Topilgan vaqt' : 'Yoʻqolgan vaqt';
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(26)),
        child: Column(
          children: [
            Semantics(
              label: 'Joy: ${listing.areaName}',
              excludeSemantics: true,
              child: row(Symbols.location_on_rounded, 'Joy', listing.areaName),
            ),
            separator,
            Semantics(
              label: '$time: ${TDate.full(listing.happenedAt)}',
              excludeSemantics: true,
              child: row(Symbols.schedule_rounded, time, TDate.full(listing.happenedAt)),
            ),
            if (showMap) ...[
              separator,
              _Tap(
                label: 'Xaritada, taxminan 300 metrlik hudud',
                onTap: () => AreaMapPage.open(context, point: listing.area, area: listing.areaName),
                child: row(Symbols.map_rounded, 'Xaritada', '~300 m hudud', chevron: true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lock + "Telefon raqamlar yashirin…" — always shown in the bottom panel.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.iconSize, this.center = false});

  final double iconSize;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall!.copyWith(fontSize: 12, height: 16 / 12, color: cs.onSurfaceVariant).inter(FontWeight.w400);
    const note = 'Telefon raqamlar yashirin. Aloqa faqat ilova ichida.';
    final lock = Icon(Symbols.lock_rounded, size: iconSize, fill: 1, color: cs.primary);
    // Centred: the lock flows with the text so it stays next to it when wrapping.
    if (center) {
      return Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(padding: const EdgeInsets.only(right: 6), child: lock),
            ),
            const TextSpan(text: note),
          ],
        ),
        textAlign: TextAlign.center,
        style: style,
      );
    }
    return Row(
      children: [
        lock,
        const SizedBox(width: 10),
        // Never truncated: 2 lines normally, 3 with large text on narrow screens.
        Flexible(child: Text(note, maxLines: 3, style: style)),
      ],
    );
  }
}

/// Pill action button, 52 high.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap, this.icon, this.bg, this.fg});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? bg, fg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final background = bg ?? (enabled ? cs.primary : cs.surfaceContainerHighest);
    final foreground = fg ?? (enabled ? cs.onPrimary : cs.onSurfaceVariant);
    return _Tap(
      label: label,
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 20, fill: 1, color: foreground), const SizedBox(width: 8)],
            // Shrinks rather than cutting off the claims count.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2),
                  style: Theme.of(context).textTheme.labelLarge!
                      .copyWith(fontSize: 16, height: 20 / 16, color: foreground)
                      .inter(FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visitor: glass capsule — privacy note left, "Bu meniki" right.
class _VisitorPanel extends StatelessWidget {
  const _VisitorPanel({required this.listing, required this.claimSent});

  static const height = 72.0;

  final Listing listing;
  final bool claimSent;

  Future<void> _claim(BuildContext context) async {
    final cubit = context.read<DetailCubit>();
    await context.push(Routes.claim(listing.id));
    await cubit.refreshClaims();
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    final Widget action = claimSent
        ? _PillButton(label: 'Soʻrov yuborildi', onTap: null, bg: tc.warningContainer, fg: tc.warning)
        : listing.isFound
        ? _PillButton(label: 'Bu meniki', onTap: () => _claim(context))
        : _PillButton(label: 'Men topdim', onTap: () => TFeedback.success(context, 'Egasiga xabar yuborildi'));
    return GlassSurface(
      color: context.glass.panel,
      padding: const EdgeInsets.fromLTRB(22, 10, 10, 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: height - 20),
        child: Row(
          children: [
            const Expanded(child: _PrivacyNote(iconSize: 18)),
            const SizedBox(width: 12),
            // Leaves the privacy note room; the label scales down instead.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.5),
              child: action,
            ),
          ],
        ),
      ),
    );
  }
}

/// Author: privacy note on top; "Qaytarildi" circle + "Soʻrovlarni koʻrish · N".
class _AuthorPanel extends StatelessWidget {
  const _AuthorPanel({required this.listing, required this.pending, required this.busy});

  static const height = 10 + 16 + 8 + 52 + 10.0;

  final Listing listing;
  final int pending;
  final bool busy;

  Future<void> _markReturned(BuildContext context) async {
    final cubit = context.read<DetailCubit>();
    final ok = await TFeedback.confirm(
      context,
      title: 'Buyum egasiga qaytarildimi?',
      body: 'Eʼlon yopiladi va lentadan olib tashlanadi.',
      confirmLabel: 'Ha, qaytarildi',
      cancelLabel: 'Bekor qilish',
    );
    if (!ok) return;
    final f = await cubit.markReturned();
    if (!context.mounted) return;
    f == null
        ? TFeedback.success(context, 'Eʼlon qaytarilgan deb belgilandi')
        : TFeedback.error(context, 'Belgilab boʻlmadi');
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    final returned = listing.status == ListingStatus.returned;
    return GlassSurface(
      radius: 34,
      color: context.glass.panel,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PrivacyNote(iconSize: 15, center: true),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!returned) ...[
                _Tap(
                  label: 'Qaytarildi deb belgilash',
                  onTap: busy ? null : () => _markReturned(context),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: tc.successContainer, shape: BoxShape.circle),
                    child: Icon(Symbols.task_alt_rounded, size: 24, color: tc.success),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _PillButton(
                  label: pending > 0 ? 'Soʻrovlarni koʻrish · $pending' : 'Soʻrovlar yoʻq',
                  icon: Symbols.verified_user_rounded,
                  onTap: pending > 0 ? () => _openClaims(context, listing) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    Widget bar(double w, double h, {double r = 6}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: ts.skeleton, borderRadius: BorderRadius.circular(r)),
    );
    return Semantics(
      label: 'Yuklanmoqda',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(double.infinity, 244, r: 28),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.only(left: 4), child: bar(90, 14)),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.only(left: 4), child: bar(220, 26)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      children: [
                        bar(22, 22, r: 11),
                        const SizedBox(width: 12),
                        bar(80, 14),
                        const Spacer(),
                        bar(110, 14),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Offline: warning-container banner with a retry.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_side, _barGap, _side, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(color: tc.warningContainer, borderRadius: BorderRadius.circular(26)),
        child: Row(
          children: [
            Icon(Symbols.wifi_off_rounded, size: 22, color: tc.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Internet yoʻq',
                    style: text.titleMedium!
                        .copyWith(fontSize: 15, height: 20 / 15, color: tc.warning)
                        .inter(FontWeight.w600),
                  ),
                  Text(
                    'Ulanishni tekshirib, qayta urinib koʻring.',
                    style: text.bodySmall!.copyWith(fontSize: 13, height: 18 / 13).inter(FontWeight.w400),
                  ),
                ],
              ),
            ),
            _Tap(
              label: 'Qayta urinish',
              onTap: onRetry,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      'Qayta urinish',
                      style: text.labelLarge!.copyWith(fontSize: 15, color: tc.warning).inter(FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
