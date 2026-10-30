import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/create_draft.dart';
import '../cubit/create_flow_cubit.dart';
import '../widgets/create_ui.dart';
import '../../../../core/theme/topildi_theme.dart';

/// Eʼlon joylandi, "big headline + swipeable cards": the posted item with a
/// check badge, a two-line headline, three "what happens next" cards that
/// page by themselves, then "Eʼlonni koʻrish", share and "Lentaga qaytish".
class PostedPage extends StatefulWidget {
  const PostedPage({super.key});

  @override
  State<PostedPage> createState() => _PostedPageState();
}

/// One "Keyin nima boʻladi?" card.
class _Step {
  const _Step(this.icon, this.text);

  final IconData icon;
  final String text;
}

class _PostedPageState extends State<PostedPage> with SingleTickerProviderStateMixin {
  /// Entry sequence: thumbnail, badge pop, headline lines, cards.
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  PageController? _pages;
  double _fraction = 0;
  int _page = 0;
  Timer? _auto;
  bool _started = false;
  static const _count = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    // A card plus its gap, as a share of the 20-inset viewport.
    final fraction = (_cardSize(mq).width + 10) / (mq.size.width - 20);
    if (fraction != _fraction) {
      final old = _pages;
      _pages = PageController(viewportFraction: fraction, initialPage: _page)..addListener(_onScroll);
      _fraction = fraction;
      if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    if (!_started) {
      _started = true;
      if (mq.disableAnimations) {
        _intro.value = 1;
      } else {
        _intro.forward();
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) HapticFeedback.mediumImpact();
        });
        _auto = Timer.periodic(const Duration(milliseconds: 3500), (_) => _next());
      }
    }
  }

  @override
  void dispose() {
    _auto?.cancel();
    _intro.dispose();
    _pages?.dispose();
    super.dispose();
  }

  /// The last card can't scroll to the left edge (no end padding), so the
  /// scroll end counts as the last page.
  void _onScroll() {
    final pages = _pages;
    if (pages == null || !pages.hasClients) return;
    final p = pages.position;
    final i = p.pixels >= p.maxScrollExtent - 1 ? _count - 1 : (pages.page ?? 0).round();
    if (i != _page) setState(() => _page = i);
  }

  void _next() {
    final pages = _pages;
    if (pages == null || !pages.hasClients) return;
    final duration = const Duration(milliseconds: 450);
    if (_page == _count - 1) {
      pages.animateToPage(0, duration: duration, curve: Curves.easeInOutCubic);
    } else if (_page == _count - 2) {
      pages.animateTo(pages.position.maxScrollExtent, duration: duration, curve: Curves.easeInOutCubic);
    } else {
      pages.animateToPage(_page + 1, duration: duration, curve: Curves.easeInOutCubic);
    }
  }

  /// The user took over the cards: no more auto paging.
  void _stopAuto() {
    _auto?.cancel();
    _auto = null;
  }

  static bool _small(MediaQueryData mq) => mq.size.height < 700;

  static Size _cardSize(MediaQueryData mq) => _small(mq) ? const Size(200, 128) : const Size(230, 150);

  Animation<double> _interval(int fromMs, int toMs, [Curve curve = Curves.easeOut]) => CurvedAnimation(
    parent: _intro,
    curve: Interval(fromMs / 700, toMs / 700, curve: curve),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final state = context.read<CreateFlowCubit>().state;
    final d = state.draft;
    final id = state.postedId;
    final small = _small(mq);
    final steps = d.isFound
        ? [
            _Step(Symbols.notifications_active_rounded, tr('Egasi yozsa, darhol xabar beramiz')),
            _Step(Symbols.lock_rounded, tr('Yashirin belgini soʻrab, egasi ekanini tekshirasiz')),
            _Step(Symbols.handshake_rounded, tr('Gavjum, xavfsiz joyda topshirasiz')),
          ]
        : [
            _Step(Symbols.notifications_active_rounded, tr('Mos eʼlon chiqsa yoki kimdir topsa, xabar beramiz')),
            _Step(Symbols.chat_rounded, tr('Topuvchi bilan faqat ilova ichidagi chatda yozishasiz')),
            _Step(Symbols.handshake_rounded, tr('Buyumni gavjum, xavfsiz joyda olasiz')),
          ];
    final open = id == null ? null : () => context.go(Routes.listing(id));
    final headline = TextStyle(
      fontSize: small ? 36 : 44,
      height: small ? 40 / 36 : 48 / 44,
      letterSpacing: -1.6,
    ).inter(FontWeight.w800);
    final cardSize = _cardSize(mq);
    // Cards grow with the text so 130% still fits three lines.
    final cardHeight = cardSize.height + math.max(0.0, mq.textScaler.scale(21) - 21) * 3;

    return PopScope(
      canPop: false,
      // Back leaves the whole create flow for the feed.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: CreateBackground()),
            CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: math.max(96, mq.padding.top + 16)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ItemRow(
                          draft: d,
                          onTap: open,
                          lift: _interval(0, 300),
                          pop: _interval(150, 570, const Cubic(0.3, 1.4, 0.5, 1)),
                        ),
                      ),
                      SizedBox(height: small ? 18 : 44),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Rise(
                              animation: _interval(120, 420),
                              child: Text(tr('Eʼlon'), style: headline.copyWith(color: cs.onSurface)),
                            ),
                            _Rise(
                              animation: _interval(200, 500),
                              child: Text(tr('joylandi!'), style: headline.copyWith(color: cs.primary)),
                            ),
                            const SizedBox(height: 12),
                            _Rise(
                              animation: _interval(280, 580),
                              child: Text(
                                d.isFound
                                    ? tr('Eʼloningiz Lentada. Egasi topilsa, darhol xabar beramiz.')
                                    : tr('Eʼloningiz Lentada. Kimdir buyumingizni topsa, darhol xabar beramiz.'),
                                style: TextStyle(fontSize: 16, height: 23 / 16, color: cs.secondary).inter(FontWeight.w400),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          tr('Keyin nima boʻladi?').toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            height: 16 / 13,
                            letterSpacing: 1,
                            color: cs.onSurfaceVariant,
                          ).inter(FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _interval(250, 600),
                        builder: (context, child) {
                          final t = _interval(250, 600).value;
                          return Opacity(
                            opacity: t,
                            child: Transform.translate(offset: Offset(40 * (1 - t), 0), child: child),
                          );
                        },
                        child: SizedBox(
                          height: cardHeight,
                          child: Listener(
                            onPointerDown: (_) => _stopAuto(),
                            child: PageView.builder(
                              controller: _pages,
                              padEnds: false,
                              itemCount: steps.length,
                              itemBuilder: (context, i) => Padding(
                                padding: EdgeInsets.only(left: i == 0 ? 20 : 0, right: 10),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: cardSize.width,
                                    height: cardHeight,
                                    child: _StepCard(index: i, step: steps[i], active: i == _page),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Dots(count: steps.length, active: _page),
                      const Spacer(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, math.max(34, mq.padding.bottom)),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _OpenButton(onTap: open)),
                                const SizedBox(width: 10),
                                _ShareButton(draft: d),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Semantics(
                              button: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => context.go(Routes.home),
                                child: SizedBox(
                                  height: 44,
                                  width: double.infinity,
                                  child: Center(
                                    child: Text(
                                      tr('Lentaga qaytish'),
                                      style: TextStyle(fontSize: 16, color: cs.primary).inter(FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades in while rising 12 px.
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) => Opacity(
      opacity: animation.value.clamp(0.0, 1.0),
      child: Transform.translate(offset: Offset(0, 12 * (1 - animation.value)), child: child),
    ),
    child: child,
  );
}

/// 96 thumbnail with the check badge, then "Faol", the title and
/// "Kategoriya · Tuman". The whole row opens the listing.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.draft, required this.onTap, required this.lift, required this.pop});

  final CreateDraft draft;
  final VoidCallback? onTap;
  final Animation<double> lift, pop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = draft;
    final category = d.category;
    final title = d.title.trim().isEmpty ? tr('Nomsiz eʼlon') : d.title.trim();
    final district = d.district;
    final meta = [?category?.label, if (district != null) tr(district)].join(' · ');
    return Semantics(
      button: onTap != null,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            _Rise(
              animation: lift,
              child: SizedBox.square(
                dimension: 96,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PhotoPlaceholder(
                      icon: category?.icon ?? Symbols.image_rounded,
                      tint: category?.index ?? 0,
                      path: d.photos.isEmpty ? null : d.photos.first,
                      width: 96,
                      height: 96,
                      iconSize: 48,
                      radius: 28,
                    ),
                    Positioned(
                      right: -14,
                      bottom: -14,
                      child: AnimatedBuilder(
                        animation: pop,
                        builder: (context, child) => Transform.scale(scale: 0.4 + 0.6 * pop.value, child: child),
                        child: SizedBox.square(
                          dimension: 48,
                          child: CustomPaint(
                            painter: _BadgePainter(color: cs.primary, ring: cs.surface),
                            child: Icon(Symbols.check_rounded, size: 22, weight: 700, color: cs.onPrimary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tr('Faol'),
                          style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer).inter(FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, color: cs.onSurface).inter(FontWeight.w700),
                  ),
                  if (meta.isNotEmpty)
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant).inter(FontWeight.w400),
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

/// Verified-style badge: a scalloped disc with a surface-coloured ring and
/// a soft primary shadow.
class _BadgePainter extends CustomPainter {
  const _BadgePainter({required this.color, required this.ring});

  final Color color, ring;

  /// Scalloped outline: radius r ± 7% over 8 bumps.
  static Path _shape(Offset c, double r) {
    final path = Path();
    const steps = 96;
    for (var i = 0; i <= steps; i++) {
      final a = 2 * math.pi * i / steps - math.pi / 2;
      final rr = r * (1 + 0.07 * math.cos(8 * a));
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 / 1.07;
    final inner = _shape(c, r - 4);
    canvas.drawPath(
      _shape(c, r - 4).shift(const Offset(0, 12)),
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
    );
    canvas.drawPath(_shape(c, r), Paint()..color = ring);
    canvas.drawPath(inner, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BadgePainter old) => old.color != color || old.ring != ring;
}

/// Card [index] of three: primary while [active], plain otherwise.
class _StepCard extends StatelessWidget {
  const _StepCard({required this.index, required this.step, required this.active});

  final int index;
  final _Step step;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: active ? 1 : 0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, t, _) => _build(
        cs,
        bg: Color.lerp(cs.surfaceContainerLowest, context.tc.primaryFill, t)!,
        fg: Color.lerp(cs.onSurface, cs.onPrimary, t)!,
        iconBg: Color.lerp(cs.primaryContainer, cs.onPrimary.withValues(alpha: dark ? 0.12 : 0.18), t)!,
        icon: Color.lerp(cs.primary, cs.onPrimary, t)!,
      ),
    );
  }

  Widget _build(ColorScheme cs, {required Color bg, required Color fg, required Color iconBg, required Color icon}) {
    return Semantics(
      label: tr('{n}-qadam: {text}', {'n': index + 1, 'text': step.text}),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(15)),
                  child: Icon(step.icon, size: 24, color: icon),
                ),
                Text(
                  '0${index + 1}',
                  style: TextStyle(fontSize: 28, height: 1, color: fg.withValues(alpha: 0.25)).inter(FontWeight.w800),
                ),
              ],
            ),
            Text(
              step.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, height: 21 / 16, color: fg).inter(FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page dots: the active one stretches to 18.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count, active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rest = Theme.of(context).brightness == Brightness.dark ? cs.outlineVariant : const Color(0xFFC8D0DE);
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: i == active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == active ? cs.primary : rest,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 56-high pill "Eʼlonni koʻrish →".
class _OpenButton extends StatelessWidget {
  const _OpenButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: context.primaryGlow(0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 17, height: 22 / 17).inter(FontWeight.w600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(tr('Eʼlonni koʻrish'), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            const Icon(Symbols.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

/// 56 circle that opens the system share sheet.
class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.draft});

  final CreateDraft draft;

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final d = draft;
    final type = d.isFound ? tr('Topilgan') : tr('Yoʻqolgan');
    final district = d.district;
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: d.title.trim(),
          text: tr('{type}: {title}\n{areaName}\n\nTopildi ilovasida koʻring.', {
            'type': type,
            'title': d.title.trim(),
            'areaName': district == null ? '' : tr(district),
          }),
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Exception {
      if (context.mounted) TFeedback.error(context, tr('Ulashib boʻlmadi'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    return Semantics(
      button: true,
      label: tr('Ulashish'),
      child: GestureDetector(
        onTap: () => _share(context),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Icon(ios ? Symbols.ios_share_rounded : Symbols.share_rounded, size: 22, color: cs.primary),
        ),
      ),
    );
  }
}
