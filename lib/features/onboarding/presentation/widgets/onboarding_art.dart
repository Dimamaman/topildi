import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/widgets/glass_surface.dart';

/// 390×360 glass scene for onboarding slide [index]: a soft blue light
/// with the slide's props laid out at their design coordinates. Chips and
/// tags pop in (scale 0.9 → 1, 120ms delay) each time the slide becomes
/// [active]. Purely decorative.
class OnboardingArt extends StatelessWidget {
  const OnboardingArt({super.key, required this.index, required this.active});

  static const width = 390.0, height = 360.0;

  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glow = dark ? const Color(0xFF8DB0FF) : const Color(0xFFE3EBFC);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: (width - 330) / 2,
              top: 10,
              child: Container(
                width: 330,
                height: 330,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glow.withValues(alpha: dark ? 0.12 : 1),
                      glow.withValues(alpha: dark ? 0.05 : 0.4),
                      glow.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.6, 0.72],
                  ),
                ),
              ),
            ),
            ...switch (index) {
              0 => _found(context, dark),
              1 => _lost(context, dark),
              _ => _safe(context, dark),
            },
          ],
        ),
      ),
    );
  }

  // 1 — "Nimadir topdingizmi?": a listing card and a camera button.
  List<Widget> _found(BuildContext context, bool dark) {
    final cs = Theme.of(context).colorScheme;
    return [
      Positioned(
        left: (width - 230) / 2,
        top: 40,
        child: Transform.rotate(
          angle: _deg(-4),
          child: Container(
            width: 230,
            height: 270,
            decoration: BoxDecoration(
              color: dark ? const Color(0xE6182031) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: dark ? const Color(0x59000000) : const Color(0x1F0F1420),
                  blurRadius: 50,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  height: 160,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF332D2A) : const Color(0xFFEFE4D8),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      Symbols.account_balance_wallet_rounded,
                      size: 64,
                      weight: 300,
                      color: dark ? const Color(0xFF9AA6BB) : const Color(0xFF4F6288),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 184,
                  child: _Pop(
                    active: active,
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        tr('Topildi'),
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(fontSize: 12, color: cs.primary).inter(FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                Positioned(left: 16, top: 220, child: _bar(230 * 0.62, 12, _skeleton(dark, 0))),
                Positioned(left: 16, top: 240, child: _bar(230 * 0.38, 10, _skeleton(dark, 1))),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 228,
        top: 230,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary,
            boxShadow: [
              BoxShadow(color: cs.primary.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 16)),
            ],
          ),
          child: Icon(Symbols.photo_camera_rounded, size: 38, color: cs.onPrimary),
        ),
      ),
    ];
  }

  // 2 — "Nimadir yoʻqotdingizmi?": feed rows under a magnifier, and a match alert.
  List<Widget> _lost(BuildContext context, bool dark) {
    final cs = Theme.of(context).colorScheme;
    Widget row(Color thumb, {double indent = 0, double opacity = 0.7}) => Opacity(
      opacity: opacity,
      child: Padding(
        padding: EdgeInsets.only(left: indent),
        child: SizedBox(
          height: 64,
          child: GlassSurface(
            radius: 20,
            color: _glassFill(dark),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: thumb, borderRadius: BorderRadius.circular(14)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(c.maxWidth * 0.7, 10, _skeleton(dark, 0)),
                        const SizedBox(height: 8),
                        _bar(c.maxWidth * 0.45, 8, _skeleton(dark, 1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return [
      Positioned(
        left: 40,
        right: 60,
        top: 70,
        child: Column(
          children: [
            row(cs.primaryContainer),
            const SizedBox(height: 10),
            row(dark ? const Color(0xFF332D2A) : const Color(0xFFEFE4D8), indent: 24, opacity: 1),
            const SizedBox(height: 10),
            row(dark ? const Color(0xFF222C40) : const Color(0xFFE6EDF2)),
          ],
        ),
      ),
      Positioned(left: 196, top: 108, child: _Magnifier(color: cs.primary)),
      Positioned(
        left: 40,
        top: 290,
        child: _Pop(
          active: active,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF212A3D) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: dark ? const Color(0x59000000) : const Color(0x1A0F1420),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.notifications_rounded, fill: 1, size: 17, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  tr('Mos eʼlon topildi'),
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(fontSize: 13, color: cs.onSurface).inter(FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  // 3 — "Xavfsiz qaytaring": glass shield tile, secret-mark tag, "Qaytarildi" pill.
  List<Widget> _safe(BuildContext context, bool dark) {
    final cs = Theme.of(context).colorScheme;
    return [
      Positioned(
        left: (width - 150) / 2,
        top: 60,
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
                  imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15, tileMode: TileMode.decal),
                  child: Opacity(
                    opacity: 0.35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(40)),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(44),
                    // CSS 160°: mostly top → bottom, leaning right.
                    gradient: LinearGradient(
                      begin: const Alignment(-0.34, -1),
                      end: const Alignment(0.34, 1),
                      colors: dark
                          ? const [Color(0xF2182031), Color(0xCC233A72)]
                          : const [Color(0xF2FFFFFF), Color(0xCCE3EBFC)],
                    ),
                    border: Border(top: BorderSide(color: dark ? const Color(0x38FFFFFF) : Colors.white)),
                    boxShadow: [
                      BoxShadow(color: cs.primary.withValues(alpha: 0.18), blurRadius: 36, offset: const Offset(0, 16)),
                    ],
                  ),
                  child: Icon(Symbols.verified_user_rounded, size: 76, weight: 300, color: cs.primary),
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: 28,
        top: 40,
        child: _Pop(
          active: active,
          child: Transform.rotate(
            angle: _deg(-6),
            child: GlassSurface(
              radius: 18,
              color: dark ? const Color(0xE6182031) : const Color(0xEBFFFFFF),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.lock_rounded, fill: 1, size: 13, color: cs.primary),
                      const SizedBox(width: 5),
                      Text(
                        tr('YASHIRIN BELGI'),
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(fontSize: 10, letterSpacing: 0.8, color: cs.primary).inter(FontWeight.w700),
                      ),
                    ],
                  ),
                  Text(
                    tr('Ichida koʻk karta'),
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(fontSize: 13, height: 18 / 13, color: cs.onSurface).inter(FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      Positioned(
        right: 30,
        top: 236,
        child: _Pop(
          active: active,
          child: Transform.rotate(
            angle: _deg(4),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(color: cs.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.task_alt_rounded, size: 19, color: cs.onPrimary),
                  const SizedBox(width: 6),
                  Text(
                    tr('Qaytarildi'),
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(fontSize: 15, color: cs.onPrimary).inter(FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  static double _deg(double d) => d * math.pi / 180;

  static Color _glassFill(bool dark) => dark ? const Color(0xE6182031) : const Color(0xE6FFFFFF);

  static Color _skeleton(bool dark, int level) => dark
      ? (level == 0 ? const Color(0xFF222C40) : const Color(0xFF1D2638))
      : (level == 0 ? const Color(0xFFE6E9EF) : const Color(0xFFEEF1F6));

  static Widget _bar(double w, double h, Color c) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(h / 2)),
  );
}

/// 120 ring (9px) with an 18×60 handle at −42°, drifting slowly left and
/// right over the rows (4s cycle) unless reduced motion is on.
class _Magnifier extends StatefulWidget {
  const _Magnifier({required this.color});

  final Color color;

  @override
  State<_Magnifier> createState() => _MagnifierState();
}

class _MagnifierState extends State<_Magnifier> with SingleTickerProviderStateMixin {
  late final _drift = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift
        ..stop()
        ..value = 0.5;
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final drift = CurvedAnimation(parent: _drift, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: drift,
      builder: (context, child) => Transform.translate(offset: Offset(-10 + 20 * drift.value, 0), child: child),
      child: SizedBox(
        width: 120,
        height: 170,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Handle: its top-left sits at (100, 106) relative to the ring.
            Positioned(
              left: 100,
              top: 106,
              child: Transform.rotate(
                angle: -42 * math.pi / 180,
                alignment: Alignment.topCenter,
                child: Container(
                  width: 18,
                  height: 60,
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(9)),
                ),
              ),
            ),
            CustomPaint(
              // Like CSS box-shadow: only outside the ring, never through the glass.
              painter: _OuterGlow(color: c.withValues(alpha: 0.25)),
              child: SizedBox.square(
                dimension: 120,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x40FFFFFF),
                        border: Border.all(color: c, width: 9),
                      ),
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

/// `0 16 30` shadow of a circle, clipped to the outside of it.
class _OuterGlow extends CustomPainter {
  const _OuterGlow({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Path()..addOval(Offset.zero & size);
    canvas.save();
    canvas.clipPath(Path.combine(PathOperation.difference, Path()..addRect((Offset.zero & size).inflate(80)), circle));
    canvas.drawPath(
      circle.shift(const Offset(0, 16)),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterGlow old) => old.color != color;
}

/// Scales 0.9 → 1 and fades in 120ms after its slide becomes active; only
/// fades when reduced motion is on.
class _Pop extends StatefulWidget {
  const _Pop({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Pop> createState() => _PopState();
}

class _PopState extends State<_Pop> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

  @override
  void initState() {
    super.initState();
    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(_Pop old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  Future<void> _play() async {
    _c.value = 0;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted && widget.active) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_c.value);
        return Opacity(
          opacity: _c.value,
          child: Transform.scale(scale: still ? 1 : 0.9 + 0.1 * t, child: child),
        );
      },
      child: widget.child,
    );
  }
}
