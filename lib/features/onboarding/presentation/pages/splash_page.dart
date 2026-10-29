import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/session/session.dart';
import '../../../../core/widgets/topildi_logo.dart';
import '../../../../core/l10n/tr.dart';

/// Brand "radar" splash; routes to onboarding, sign-in or the feed.
///
/// Continues the native launch screen (`flutter_native_splash` in
/// pubspec.yaml): brand blue with the same 116 pt white tile at the screen
/// centre, so the hand-over doesn't show. Then rings spread from the tile,
/// lost items pop up around it and the wallet is "found" — ≈1.8 s in all,
/// after which the splash fades out and the next screen opens.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// Tile size, matching `assets/brand/splash/splash-icon.png` (348 px @3x).
  static const tileSize = 116.0;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

/// Radar ring radii and opacities, inner → outer.
const _rings = [(90.0, 0.35), (150.0, 0.22), (220.0, 0.14), (300.0, 0.08)];

/// Items around the tile: radius, angle (0° = right, clockwise) and when it pops up.
const _items = [
  (Symbols.key_rounded, 150.0, 160.0, 550),
  (Symbols.smartphone_rounded, 220.0, 60.0, 700),
  (Symbols.headphones_rounded, 220.0, -140.0, 850),
  (Symbols.watch_rounded, 300.0, -100.0, 1000),
  (Symbols.backpack_rounded, 300.0, 125.0, 1100),
  (Symbols.account_balance_wallet_rounded, 150.0, -35.0, 1250),
];

/// The wallet is the found one: it lights up at 1.35 s.
const _foundAt = 1350;

const _total = 1800;

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  /// Whole timeline in ms (0 … [_total]).
  late final _t = AnimationController(vsync: this, duration: const Duration(milliseconds: _total));

  /// Endless pulse from the inner ring, from 400 ms until the splash closes.
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  /// Closing fade + slight zoom.
  late final _out = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

  final _timers = <Timer>[];
  var _started = false, _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Everything at its final state, faded in over 200 ms; no pulse or sweep.
      _t.animateTo(1, duration: const Duration(milliseconds: 200));
    } else {
      _t.forward();
      _timers
        ..add(Timer(const Duration(milliseconds: 400), () => _pulse.repeat()))
        ..add(Timer(const Duration(milliseconds: _foundAt), HapticFeedback.lightImpact));
    }
    _timers.add(Timer(const Duration(milliseconds: _total), _continue));
  }

  Future<void> _continue() async {
    if (!mounted || _leaving) return;
    _leaving = true;
    for (final t in _timers) {
      t.cancel();
    }
    await _out.forward();
    if (!mounted) return;
    final session = getIt<Session>();
    context.go(session.signedIn ? Routes.home : (session.onboardingSeen ? Routes.signIn : Routes.onboarding));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _t.dispose();
    _pulse.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Semantics(
          label: tr('Topildi — yuklanmoqda'),
          child: GestureDetector(
            onTap: _continue,
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _out,
              builder: (context, child) {
                final v = Curves.easeIn.transform(_out.value);
                return Opacity(
                  opacity: 1 - v,
                  child: Transform.scale(scale: 1 + 0.04 * v, child: child),
                );
              },
              child: ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, c) => _Scene(
                    size: c.biggest,
                    t: _t,
                    pulse: _pulse,
                    // With reduced motion the timeline only drives a 200 ms fade.
                    still: still,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({required this.size, required this.t, required this.pulse, required this.still});

  final Size size;
  final AnimationController t, pulse;
  final bool still;

  /// Progress of the segment [startMs, startMs + durMs] on the timeline.
  double _seg(int startMs, int durMs, [Curve curve = Curves.linear]) {
    if (still) return t.value;
    final ms = t.value * _total;
    return curve.transform(((ms - startMs) / durMs).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    // Same centre as the native splash image.
    final centre = size.center(Offset.zero);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Native blue, then the radial gradient fades in over 200 ms.
        const Positioned.fill(child: ColoredBox(color: BrandColors.blue)),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: t,
            builder: (context, child) => Opacity(opacity: still ? 1 : _seg(0, 200), child: child),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  // CSS `circle` reaches the farthest corner.
                  radius: (size.width / 2).hypot(size.height / 2) / size.shortestSide,
                  colors: const [Color(0xFF3A72F0), BrandColors.blue, BrandColors.gradientTo],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _RadarPainter(
                centre: centre,
                repaint: Listenable.merge([t, pulse]),
                ring: (i) => _seg(i * 150, 700, const Cubic(0.2, 1, 0.3, 1)),
                sweep: () => still ? null : _seg(300, 1300),
                pulse: () => still || pulse.isDismissed && !pulse.isAnimating ? null : pulse.value,
              ),
            ),
          ),
        ),
        for (final (icon, r, deg, at) in _items)
          _positioned(
            centre + Offset.fromDirection(deg * math.pi / 180, r),
            34,
            AnimatedBuilder(
              animation: t,
              builder: (context, _) {
                final p = _seg(at, 350, const Cubic(0.2, 1.4, 0.3, 1));
                final found = at == 1250 ? _seg(_foundAt, 500, Curves.easeOut) : 0.0;
                return Opacity(
                  opacity: p.clamp(0.0, 1.0),
                  child: Transform.scale(scale: 0.5 + 0.5 * p, child: _Item(icon: icon, found: found)),
                );
              },
            ),
          ),
        _positioned(
          centre,
          SplashPage.tileSize,
          AnimatedBuilder(
            animation: t,
            builder: (context, child) {
              // "Breath" 1 → 1.06 → 1 over the first 400 ms.
              final b = _seg(0, 400);
              return Transform.scale(scale: still ? 1 : 1 + 0.06 * math.sin(b * math.pi), child: child);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
                boxShadow: const [BoxShadow(color: Color(0x4D0F1420), blurRadius: 44, offset: Offset(0, 20))],
              ),
              alignment: Alignment.center,
              // 54 wide, as in splash-icon.png.
              child: const TopildiMark.blue(height: 54 * 140 / 106),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 74,
          child: AnimatedBuilder(
            animation: t,
            builder: (context, child) {
              final w = _seg(900, 400, Curves.easeOut);
              return Opacity(
                opacity: w,
                child: Transform.translate(offset: Offset(0, 10 * (1 - w)), child: child),
              );
            },
            child: Column(
              children: [
                // Brand name: Latin in every language.
                const TopildiWordmark(fontSize: 30, onDark: true),
                const SizedBox(height: 4),
                Text(
                  tr('Topilgan buyum egasiga qaytadi'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 20 / 14, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _positioned(Offset c, double size, Widget child) =>
      Positioned(left: c.dx - size / 2, top: c.dy - size / 2, width: size, height: size, child: child);
}

/// 34×34 frosted item tile; [found] (0 → 1) turns it white with a blue icon
/// and a warm halo.
class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.found});

  final IconData icon;
  final double found;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0x24FFFFFF), Colors.white, found),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.lerp(const Color(0x33FFFFFF), Colors.white, found)!),
        boxShadow: found == 0
            ? null
            : [
                BoxShadow(color: BrandColors.dotOnDark.withValues(alpha: 0.35 * found), spreadRadius: 6),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2 * found),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: Color.lerp(Colors.white, BrandColors.blue, found)),
    );
  }
}

/// Rings, the one-off radar sweep and the repeating pulse, all centred on the tile.
class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.centre,
    required Listenable repaint,
    required this.ring,
    required this.sweep,
    required this.pulse,
  }) : super(repaint: repaint);

  final Offset centre;

  /// Appearance progress of ring i (scale 0.6 → 1, opacity 0 → 1).
  final double Function(int i) ring;

  /// Sweep progress 0 → 1, or null when there is none.
  final double? Function() sweep;

  /// Pulse cycle 0 → 1, or null before it starts.
  final double? Function() pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final s = sweep();
    if (s != null && s > 0 && s < 1) {
      // CSS conic starts at 12 o'clock; Flutter's sweep at 3 o'clock.
      final angle = (-120 + 360 * s) * math.pi / 180 - math.pi / 2;
      final opacity = s < 0.85 ? 1.0 : (1 - s) / 0.15;
      final rect = Rect.fromCircle(center: centre, radius: 300);
      canvas.drawCircle(
        centre,
        300,
        Paint()
          ..shader = SweepGradient(
            colors: [
              Colors.white.withValues(alpha: 0.16 * opacity),
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, 55 / 360, 1],
            transform: GradientRotation(angle),
          ).createShader(rect),
      );
    }

    final p = pulse();
    if (p != null) {
      final e = Curves.easeOut.transform(p);
      canvas.drawCircle(
        centre,
        90 * (0.6 + 2.8 * e),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.5 * 0.6 * (1 - e)),
      );
    }

    for (var i = 0; i < _rings.length; i++) {
      final (r, a) = _rings[i];
      final v = ring(i);
      if (v <= 0) continue;
      canvas.drawCircle(
        centre,
        r * (0.6 + 0.4 * v),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: a * v.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.centre != centre;
}

extension on double {
  double hypot(double other) => math.sqrt(this * this + other * other);
}
