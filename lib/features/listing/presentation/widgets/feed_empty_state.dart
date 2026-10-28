import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/glass_empty_icon.dart';

/// Lenta with nothing to show: a glass icon tile, a title and a hint, and a
/// dashed arrow pointing at the floating "+" button. Fills the space between
/// the pinned header and the tab bar; the arrow is hidden when it would run
/// into the text.
class FeedEmptySliver extends StatelessWidget {
  const FeedEmptySliver({super.key, required this.lost, this.icon, required this.title, required this.lead});

  /// Yoʻqolgan tab: the glow takes the "lost" colour.
  final bool lost;

  /// Tile icon; defaults to an empty box.
  final IconData? icon;
  final String title;

  /// Hint text before "+ tugmasi orqali.".
  final String lead;

  static const _side = 28.0, _icon = 150.0, _gapIcon = 22.0, _gapText = 6.0, _bodyInset = 12.0;

  /// Space between the category chips and the block on tall screens.
  static const _maxTop = 68.0;

  /// Arrow box: 30 from the right edge, its bottom 10 above the tab bar.
  static const _arrow = 150.0, _arrowRight = 30.0, _arrowBottom = 10.0;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, c) {
        // The floating tab bar's height arrives as bottom padding.
        final nav = MediaQuery.paddingOf(context).bottom;
        final area = math.max(0.0, c.viewportMainAxisExtent - c.precedingScrollExtent - nav);
        final textWidth = c.crossAxisExtent - _side * 2;
        final scaler = MediaQuery.textScalerOf(context);
        double measure(InlineSpan span, double width) {
          final painter = TextPainter(
            text: span,
            textAlign: TextAlign.center,
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout(maxWidth: width);
          final h = painter.height;
          painter.dispose();
          return h;
        }

        final content =
            _icon +
            _gapIcon +
            measure(TextSpan(text: title, style: _titleStyle(context)), textWidth) +
            _gapText +
            measure(_bodySpan(context), textWidth - _bodyInset * 2);
        final top = ((area - content) / 2).clamp(0.0, _maxTop);
        final arrowTop = area - _arrowBottom - _arrow;
        final showArrow = arrowTop >= top + content + 8;
        return SliverToBoxAdapter(
          child: SizedBox(
            height: math.max(area, top + content + 24),
            child: Stack(
              children: [
                Positioned(
                  top: top,
                  left: _side,
                  right: _side,
                  child: Column(
                    children: [
                      GlassEmptyIcon(
                        icon: icon ?? Symbols.inventory_2_rounded,
                        glow: lost ? context.tc.lost.withValues(alpha: 0.25) : null,
                      ),
                      const SizedBox(height: _gapIcon),
                      Semantics(
                        header: true,
                        child: Text(title, textAlign: TextAlign.center, style: _titleStyle(context)),
                      ),
                      const SizedBox(height: _gapText),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: _bodyInset),
                        child: Text.rich(_bodySpan(context), textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
                if (showArrow)
                  const Positioned(
                    right: _arrowRight,
                    bottom: _arrowBottom,
                    width: _arrow,
                    height: _arrow,
                    child: ExcludeSemantics(child: _HintArrow()),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle _titleStyle(BuildContext context) => Theme.of(context).textTheme.headlineSmall!
      .copyWith(fontSize: 24, height: 30 / 24, letterSpacing: -0.4, color: Theme.of(context).colorScheme.onSurface)
      .inter(FontWeight.w700);

  TextSpan _bodySpan(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: 15, height: 21 / 15, color: cs.onSurfaceVariant).inter(FontWeight.w400);
    return TextSpan(
      style: base,
      children: [
        TextSpan(text: lead),
        TextSpan(
          text: '+',
          style: base.copyWith(color: cs.primary).inter(FontWeight.w700),
        ),
        TextSpan(text: tr(' tugmasi orqali.')),
      ],
    );
  }
}

/// Dashed curve that is drawn in once (700ms after a 300ms pause), then the
/// open "V" head appears.
class _HintArrow extends StatefulWidget {
  const _HintArrow();

  @override
  State<_HintArrow> createState() => _HintArrowState();
}

class _HintArrowState extends State<_HintArrow> with SingleTickerProviderStateMixin {
  late final _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  late final _progress = CurvedAnimation(
    parent: _draw,
    curve: const Interval(0.3, 1, curve: Curves.easeOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _draw.value = 1;
    } else if (_draw.isDismissed) {
      _draw.forward();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ArrowPainter(progress: _progress, color: context.ts.hint),
  );
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.progress, required this.color}) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  static const _dash = 6.0, _gap = 7.0;

  // Design coordinates in a 150×150 box.
  static final _curve = Path()
    ..moveTo(30, 46)
    ..cubicTo(96, 52, 128, 82, 122, 128);
  static final _head = Path()
    ..moveTo(110, 118)
    ..lineTo(122, 134)
    ..lineTo(134, 117);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 150, size.height / 150);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final t = progress.value;
    for (final PathMetric m in _curve.computeMetrics()) {
      final end = m.length * t;
      for (var d = 0.0; d < end; d += _dash + _gap) {
        canvas.drawPath(m.extractPath(d, math.min(d + _dash, end)), paint);
      }
    }
    if (t >= 1) canvas.drawPath(_head, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color || old.progress != progress;
}
