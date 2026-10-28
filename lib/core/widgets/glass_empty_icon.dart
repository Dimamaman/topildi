import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/topildi_theme.dart';

/// Corner mark on [GlassEmptyIcon].
enum GlassIconBadge {
  /// Breathing sparkle plus two dots (Lenta).
  sparkle,

  /// White disc with a lock plus one dot (Chatlar).
  lock,
}

/// Empty-state art shared by Lenta and Chatlar, 150×150: blurred glow, a
/// 120 glass squircle with the icon, and a corner badge with decorative
/// dots. The tile floats gently and the sparkle breathes unless the system
/// asks for reduced motion.
class GlassEmptyIcon extends StatefulWidget {
  const GlassEmptyIcon({
    super.key,
    required this.icon,
    this.iconSize = 64,
    this.iconFill = false,
    this.glow,
    this.badge = GlassIconBadge.sparkle,
  });

  final IconData icon;
  final double iconSize;

  /// Filled glyph, as on the tab bar.
  final bool iconFill;

  /// Glow colour; defaults to primary at 35% (25% in dark).
  final Color? glow;
  final GlassIconBadge badge;

  @override
  State<GlassEmptyIcon> createState() => _GlassEmptyIconState();
}

class _GlassEmptyIconState extends State<GlassEmptyIcon> with TickerProviderStateMixin {
  late final _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final _sparkle = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
      _sparkle.stop();
      _float.value = 0;
      _sparkle.value = 1;
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
      _sparkle.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glow = widget.glow ?? cs.primary.withValues(alpha: dark ? 0.25 : 0.35);
    final lock = widget.badge == GlassIconBadge.lock;
    final sparkle = dark ? cs.primary : cs.inversePrimary;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 150,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: 20,
              top: 20,
              right: 20,
              bottom: 20,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30, tileMode: TileMode.decal),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: glow, borderRadius: BorderRadius.circular(40)),
                ),
              ),
            ),
            Positioned.fill(
              left: 15,
              top: 15,
              right: 15,
              bottom: 15,
              child: AnimatedBuilder(
                animation: _float,
                builder: (context, child) =>
                    Transform.translate(offset: Offset(0, -4 * Curves.easeInOut.transform(_float.value)), child: child),
                child: _Tile(icon: widget.icon, size: widget.iconSize, fill: widget.iconFill),
              ),
            ),
            if (lock)
              Positioned(
                right: -4,
                top: 6,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: dark ? cs.surfaceContainerLowest : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x1F0F1420), blurRadius: 14, offset: Offset(0, 6))],
                  ),
                  child: Icon(Symbols.lock_rounded, size: 18, fill: 1, color: cs.primary),
                ),
              )
            else
              Positioned(
                right: -6,
                top: 0,
                child: FadeTransition(
                  opacity: Tween(begin: 0.6, end: 1.0).animate(_sparkle),
                  child: Icon(Symbols.auto_awesome_rounded, size: 22, fill: 1, color: sparkle),
                ),
              ),
            Positioned(left: 0, bottom: 18, child: _Dot(size: 10, color: TopildiColors.dark.lost)),
            if (!lock) Positioned(right: 8, bottom: 0, child: _Dot(size: 7, color: TopildiColors.dark.found)),
          ],
        ),
      ),
    );
  }
}

/// 120×120 glass squircle: diagonal white-to-blue wash, a light rim that is
/// brightest along the top edge, and a soft drop shadow.
class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.size, required this.fill});

  final IconData icon;
  final double size;
  final bool fill;

  // CSS 160°: from the top, a little left, to the bottom, a little right.
  static const _begin = Alignment(-0.34, -0.94), _end = Alignment(0.34, 0.94);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final white = cs.surfaceContainerLowest;
    final (from, to) = dark
        ? (Colors.white.withValues(alpha: 0.10), cs.primary.withValues(alpha: 0.08))
        : (white.withValues(alpha: 0.95), cs.primaryContainer.withValues(alpha: 0.8));
    final (rimTop, rim) = dark
        ? (Colors.white.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0.12))
        : (white, white.withValues(alpha: 0.7));
    return CustomPaint(
      foregroundPainter: _RimPainter(top: rimTop, rest: rim),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(begin: _begin, end: _end, colors: [from, to]),
          boxShadow: [
            BoxShadow(
              color: dark ? Colors.black.withValues(alpha: 0.45) : cs.primary.withValues(alpha: 0.18),
              offset: const Offset(0, 16),
              blurRadius: 36,
            ),
          ],
        ),
        child: Icon(icon, size: size, weight: 300, fill: fill ? 1 : 0, color: cs.primary),
      ),
    );
  }
}

class _RimPainter extends CustomPainter {
  const _RimPainter({required this.top, required this.rest});

  final Color top, rest;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(40)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, rest, rest],
          stops: const [0, 0.12, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.top != top || old.rest != rest;
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
