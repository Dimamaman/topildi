import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/topildi_logo.dart';
import '../cubit/sign_in_cubit.dart';
import '../../../../core/l10n/tr.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<SignInCubit>(), child: const _SignInView());
  }
}

/// Positions below are for a 390-wide screen (the design); x scales with
/// the width. Under 700 tall the cloud shrinks to 80% height, the app icon
/// to 88 and the tiles below y 400 are left out.
const _designWidth = 390.0;
const _appY = 270.0;
const _appSize = 104.0;
const _smallHeight = 700.0;

/// Collection timing: each tile flies 520ms, 60ms after the previous one.
const _flyMs = 520;
const _fadeMs = 420;
const _staggerMs = 60;
const _collectMs = _flyMs + 11 * _staggerMs;

/// Coming back: 400ms each, 40ms apart.
const _backMs = 400;
const _backStaggerMs = 40;

const _flyCurve = Cubic(0.5, 0, 0.75, 0);

/// Back from Telegram the radar runs for at least this long, then the
/// wallet (tile 0, as on the splash) is "found" and the next screen opens.
const _radarMinMs = 900;
const _foundMs = 520;
const _foundHoldMs = 380;
const _foundTile = 0;

/// One lost-and-found item around the app icon.
class _Tile {
  const _Tile(this.icon, this.color, this.x, this.y, this.size, this.degrees, [this.opacity = 1]);

  final IconData icon;
  final Color color;

  /// Centre on the 390-wide design.
  final double x, y, size, degrees, opacity;
}

/// In this order they fly in.
const _tiles = [
  _Tile(Symbols.account_balance_wallet, Color(0xFFEFE4D8), 50, 90, 44, -12),
  _Tile(Symbols.key, Color(0xFFFBEFD6), 330, 70, 50, 14),
  _Tile(Symbols.headphones, Color(0xFFEBE6F3), 200, 40, 56, -4),
  _Tile(Symbols.smartphone, Color(0xFFDDE4F0), 40, 250, 44, 9),
  _Tile(Symbols.badge, Color(0xFFE3EBFC), 350, 240, 50, -8),
  _Tile(Symbols.backpack, Color(0xFFDCEFE4), 110, 400, 56, 6),
  _Tile(Symbols.watch, Color(0xFFFBE3D2), 290, 390, 44, -10),
  // Close to the text, so half transparent.
  _Tile(Symbols.umbrella, Color(0xFFDCEFE4), 30, 520, 50, 8, 0.5),
  _Tile(Symbols.photo_camera, Color(0xFFEFE4D8), 360, 500, 56, -6, 0.5),
  _Tile(Symbols.pets, Color(0xFFFBEFD6), 205, 470, 44, 4, 0.5),
  _Tile(Symbols.eyeglasses, Color(0xFFEBE6F3), 130, 150, 50, 10),
  _Tile(Symbols.credit_card, Color(0xFFDDE4F0), 270, 140, 56, -14),
];

/// How the tiles are moving: resting, flying in, flying back, or (reduced
/// motion) only fading.
enum _Fly { rest, collect, back, fade }

/// Kirish, "icon cloud": lost-and-found items float around the app icon;
/// title, the Telegram button and the terms sit at the bottom. Tapping the
/// button gathers the items into the icon, then opens the bot. Coming back
/// before the number was shared sends them back to their places. While the
/// result is checked a radar spreads from the icon; on success the wallet is
/// "found" (white, blue icon, gold ring) and the next screen opens.
class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> with TickerProviderStateMixin {
  late final _collect = AnimationController(vsync: this, duration: const Duration(milliseconds: _collectMs));
  late final _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _backMs + 11 * _backStaggerMs),
  );
  late final _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  late final _pulseScale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12).chain(CurveTween(curve: Curves.easeOutBack)), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 1),
  ]).animate(_pulse);
  /// Radar layer fade in/out, and its endless turn (sweep + pulses).
  late final _radarIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final _radarTurn = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  late final _found = AnimationController(vsync: this, duration: const Duration(milliseconds: _foundMs));
  late final AppLifecycleListener _lifecycle;

  _Fly _fly = _Fly.rest;

  /// "Telegram ochilmoqda…" on the button, from 1300ms until the tiles come back.
  bool _opening = false;

  /// The app went to the background (Telegram opened) since the tap.
  bool _left = false;

  /// Signed in: the found tile plays, then the next screen opens.
  bool _finishing = false;

  DateTime? _radarSince;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _left = true,
      onResume: () {
        if (!_left) return;
        _left = false;
        context.read<SignInCubit>().resumed();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _collect.dispose();
    _back.dispose();
    _fade.dispose();
    _pulse.dispose();
    _radarIn.dispose();
    _radarTurn.dispose();
    _found.dispose();
    super.dispose();
  }

  Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  Future<void> _go() async {
    final cubit = context.read<SignInCubit>();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (!await cubit.begin() || !mounted) return;
    HapticFeedback.lightImpact();
    if (reduce) {
      setState(() => _fly = _Fly.fade);
      await _fade.forward(from: 0);
    } else {
      setState(() => _fly = _Fly.collect);
      _collect.forward(from: 0);
      await _wait(1100);
      if (!mounted) return;
      _pulse.forward(from: 0);
      HapticFeedback.mediumImpact();
      await _wait(200);
    }
    if (!mounted) return;
    setState(() => _opening = true);
    if (!reduce) await _wait(100);
    if (!mounted) return;
    if (!await cubit.open() && mounted) _bringBack();
  }

  /// Sends the tiles home; completes once they are there.
  Future<void> _bringBack() async {
    setState(() => _opening = false);
    try {
      if (_fly == _Fly.fade) {
        await _fade.reverse().orCancel;
      } else if (_fly == _Fly.collect) {
        setState(() => _fly = _Fly.back);
        await _back.forward(from: 0).orCancel;
      } else if (_fly == _Fly.back && _back.isAnimating) {
        await _wait(((1 - _back.value) * _back.duration!.inMilliseconds).round());
      }
    } on TickerCanceled {
      // Disposed.
    }
  }

  void _startRadar() {
    if (_radarSince != null) return;
    _radarSince = DateTime.now();
    _radarIn.forward();
    if (!MediaQuery.disableAnimationsOf(context)) _radarTurn.repeat();
  }

  Future<void> _stopRadar() async {
    _radarSince = null;
    await _radarIn.reverse();
    if (_radarSince == null) _radarTurn.stop();
  }

  /// Back from Telegram: tiles come home under the radar.
  void _checking() {
    _startRadar();
    _bringBack();
  }

  /// Signed in: tiles home, radar for at least [_radarMinMs], the wallet is
  /// found, a beat, then [route].
  Future<void> _finish(String route) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final reduce = MediaQuery.disableAnimationsOf(context);
    _startRadar();
    final since = _radarSince!;
    await _bringBack();
    if (!mounted) return;
    if (!reduce) {
      final left = _radarMinMs - DateTime.now().difference(since).inMilliseconds;
      if (left > 0) await _wait(left);
      if (!mounted) return;
    }
    HapticFeedback.mediumImpact();
    await _found.animateTo(1, duration: Duration(milliseconds: reduce ? 200 : _foundMs));
    if (!mounted) return;
    await _wait(reduce ? 200 : _foundHoldMs);
    if (mounted) context.go(route);
  }

  /// 0 at home → 1 at the app icon, and the opacity factor, for tile [i].
  (double, double) _progress(int i) {
    double local(AnimationController c, int totalMs, int startMs, int lengthMs) =>
        ((c.value * totalMs - startMs) / lengthMs).clamp(0.0, 1.0);
    switch (_fly) {
      case _Fly.rest:
        return (0, 1);
      case _Fly.fade:
        return (0, 1 - _fade.value);
      case _Fly.collect:
        final fly = _flyCurve.transform(local(_collect, _collectMs, i * _staggerMs, _flyMs));
        final fade = Curves.easeIn.transform(local(_collect, _collectMs, i * _staggerMs, _fadeMs));
        return (fly, 1 - fade);
      case _Fly.back:
        final total = _backMs + 11 * _backStaggerMs;
        final q = Curves.easeOutCubic.transform(local(_back, total, i * _backStaggerMs, _backMs));
        return (1 - q, q);
    }
  }

  /// Found progress of tile [i], and how much the others fade meanwhile.
  (double, double) _foundOf(int i) {
    final f = _found.value;
    return i == _foundTile ? (f, 1) : (0, 1 - 0.45 * f);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: BlocConsumer<SignInCubit, SignInState>(
        listenWhen: (a, b) =>
            a.next != b.next ||
            (a.phase != SignInPhase.checking && b.phase == SignInPhase.checking) ||
            ((a.phase == SignInPhase.waiting || a.phase == SignInPhase.checking) && b.phase == SignInPhase.idle),
        listener: (context, state) {
          switch (state.next) {
            case SignInNext.profile:
              _finish(Routes.profileSetup);
            case SignInNext.home:
              _finish(Routes.home);
            case SignInNext.none when state.phase == SignInPhase.checking:
              _checking();
            case SignInNext.none:
              // Back from Telegram without sharing the number.
              _stopRadar();
              _bringBack();
          }
        },
        builder: (context, state) {
          final busy = state.phase != SignInPhase.idle || _finishing;
          final checking = state.phase == SignInPhase.checking || _finishing;
          return Scaffold(
            backgroundColor: dark ? const Color(0xFF000000) : const Color(0xFFF4F6FA),
            body: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                final small = box.maxHeight < _smallHeight;
                final ky = small ? 0.8 : 1.0;
                final kx = w / _designWidth;
                final appSize = small ? 88.0 : _appSize;
                final app = Offset(w / 2, _appY * ky);
                final tiles = [
                  for (final (i, t) in _tiles.indexed)
                    if (!small || t.y <= 400) (i, t, Offset(t.x * kx, t.y * ky)),
                ];
                return Stack(
                  children: [
                    Positioned.fill(child: _Background(dark: dark)),
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _RadarPainter(
                            centre: app,
                            scale: appSize / _appSize,
                            color: dark ? const Color(0xFF4D7FFF) : cs.primary,
                            show: _radarIn,
                            turn: _radarTurn,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: ExcludeSemantics(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_collect, _back, _fade, _found]),
                            builder: (context, _) => Stack(
                              children: [
                                for (final (i, t, at) in tiles)
                                  Positioned(
                                    left: at.dx - t.size / 2,
                                    top: at.dy - t.size / 2,
                                    child: _FlyingTile(
                                      tile: t,
                                      toApp: app - at,
                                      progress: _progress(i),
                                      found: _foundOf(i),
                                      dark: dark,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: app.dx - appSize / 2 - _AppIcon.ring,
                      top: app.dy - appSize / 2 - _AppIcon.ring,
                      child: ScaleTransition(
                        scale: _pulseScale,
                        child: _AppIcon(size: appSize, dark: dark),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    tr('Xush kelibsiz!'),
                                    textAlign: TextAlign.center,
                                    style: text.headlineMedium!
                                        .copyWith(fontSize: 34, height: 40 / 34, letterSpacing: -0.8, color: cs.onSurface)
                                        .inter(FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tr('Yoʻqotganingizni toping, topganingizni qaytaring. Kirish — bir bosishda.'),
                                  textAlign: TextAlign.center,
                                  style: text.bodyLarge!
                                      .copyWith(fontSize: 16, height: 23 / 16, color: cs.secondary)
                                      .inter(FontWeight.w400),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TelegramButton(
                                  label: checking
                                      ? tr('Tekshirilmoqda…')
                                      : (_opening || state.phase == SignInPhase.waiting ? tr('Telegram ochilmoqda…') : null),
                                  onTap: busy ? null : _go,
                                ),
                                if (state.error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        state.error!,
                                        textAlign: TextAlign.center,
                                        style: text.bodySmall!
                                            .copyWith(fontSize: 13, height: 18 / 13, color: cs.error)
                                            .inter(FontWeight.w500),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32 - _Terms.pad),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 32), child: _Terms()),
                          const SizedBox(height: 30 - _Terms.pad),
                        ],
                      ),
                    ),
                    if (state.offline)
                      Positioned(left: 16, right: 16, top: top + 8, child: const _OfflineBanner()),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Top-to-bottom wash with a soft light behind the app icon.
class _Background extends StatelessWidget {
  const _Background({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    // The light reaches ≈40% of the way to the farthest corner (≈242 on 390×844).
    const light = RadialGradient(
      center: Alignment(0, -0.36),
      radius: 0.62,
      colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
    );
    const darkLight = RadialGradient(
      center: Alignment(0, -0.36),
      radius: 0.62,
      colors: [Color(0xFF0A1430), Color(0x000A1430)],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF000000) : null,
        gradient: dark
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAF0FB), Color(0xFFF4F6FA)],
              ),
      ),
      child: DecoratedBox(decoration: BoxDecoration(gradient: dark ? darkLight : light)),
    );
  }
}

/// A tile on its way to the app icon: [progress] is (0 home → 1 at the
/// icon, opacity factor); it shrinks to 0.2 as it arrives. [found] is (0 → 1
/// turning white with a blue icon and a gold ring, opacity factor while
/// another tile is found).
class _FlyingTile extends StatelessWidget {
  const _FlyingTile({
    required this.tile,
    required this.toApp,
    required this.progress,
    required this.found,
    required this.dark,
  });

  final _Tile tile;
  final Offset toApp;
  final (double, double) progress, found;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final (p, fade) = progress;
    final (f, dim) = found;
    final s = tile.size;
    final r = BorderRadius.circular(s * 0.34);
    final base = dark ? const Color(0x14FFFFFF) : tile.color;
    final ink = dark ? const Color(0xFF8E95A3) : const Color(0xFF4F6288);
    return Opacity(
      opacity: (tile.opacity * fade * dim).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: toApp * p,
        child: Transform.scale(
          // Found: a 1 → 1.22 → 1.12 pop.
          scale: (1 - 0.8 * p) * (1 + 0.12 * f + 0.1 * math.sin(f * math.pi)),
          child: Transform.rotate(
            // Found: straightens up.
            angle: tile.degrees * (1 - f) * math.pi / 180,
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                color: Color.lerp(base, Colors.white, f),
                borderRadius: r,
                border: dark ? Border.all(color: Color.lerp(const Color(0x1FFFFFFF), Colors.white, f)!) : null,
                boxShadow: [
                  if (f > 0) ...[
                    BoxShadow(color: BrandColors.dotOnDark.withValues(alpha: f), spreadRadius: 3),
                    BoxShadow(color: BrandColors.dotOnDark.withValues(alpha: 0.45 * f), spreadRadius: 3, blurRadius: 20),
                  ],
                  const BoxShadow(color: Color(0x1A0F1420), offset: Offset(0, 10), blurRadius: 22),
                ],
              ),
              // 1px inner light along the top edge.
              foregroundDecoration: dark || f > 0
                  ? null
                  : BoxDecoration(
                      borderRadius: r,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: const [Color(0xB3FFFFFF), Color(0x00FFFFFF)],
                        stops: [0, 1.5 / s],
                      ),
                    ),
              alignment: Alignment.center,
              child: Icon(
                tile.icon,
                size: s * 0.48,
                fill: f,
                weight: 300 + 200 * f,
                color: Color.lerp(ink, BrandColors.blue, f),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The "t." app icon, inside a 12px white ring and
/// a 1px primary hairline, with a deep soft shadow.
class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.size, required this.dark});

  /// Ring plus hairline around the icon.
  static const ring = 13.0;

  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final k = size / _appSize;
    final radius = 33 * k;
    return Semantics(
      label: 'Topildi',
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size + 2 * ring,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: dark ? const Color(0x66000000) : const Color(0x4D0B2A6B),
                    offset: const Offset(0, 20),
                    blurRadius: 44,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: dark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(radius + ring),
              ),
              child: Container(
                padding: const EdgeInsets.all(ring - 1),
                decoration: BoxDecoration(
                  color: dark ? const Color(0x1AFFFFFF) : const Color(0xE6FFFFFF),
                  borderRadius: BorderRadius.circular(radius + ring - 1),
                ),
                child: TopildiAppIcon(size: size, radius: radius),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 58px primary capsule with the paper plane; scales to 0.97 while pressed.
/// [label]: spinner and that text ("Telegram ochilmoqda…", "Tekshirilmoqda…")
/// instead of the plane. Null [onTap]: not tappable.
class _TelegramButton extends StatefulWidget {
  const _TelegramButton({required this.label, required this.onTap});

  final String? label;
  final VoidCallback? onTap;

  @override
  State<_TelegramButton> createState() => _TelegramButtonState();
}

class _TelegramButtonState extends State<_TelegramButton> {
  bool _pressed = false;

  void _press(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = widget.onTap != null;
    final busy = widget.label != null;
    final label = widget.label ?? tr('Telegram orqali kirish');
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      liveRegion: busy,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => _press(true) : null,
        onTapUp: enabled ? (_) => _press(false) : null,
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [BoxShadow(color: context.primaryGlow(0.3), offset: const Offset(0, 12), blurRadius: 28)],
            ),
            // 1px inner light along the top edge.
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
                stops: [0, 1.5 / 58],
              ),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy)
                    SizedBox.square(dimension: 22, child: CupertinoActivityIndicator(color: cs.onPrimary, radius: 10))
                  else
                    Icon(Symbols.send_rounded, size: 22, fill: 1, color: cs.onPrimary),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge!
                        .copyWith(fontSize: 17, height: 22 / 17, color: cs.onPrimary)
                        .inter(FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Davom etish orqali Foydalanish shartlari va Maxfiylik siyosatiga
/// rozilik bildirasiz." Each link answers taps up to 22 above and below its
/// line (a 44 target), picking the nearer line where two overlap.
class _Terms extends StatefulWidget {
  const _Terms();

  /// Invisible padding above and below that the larger targets reach into.
  static const pad = 13.0;

  @override
  State<_Terms> createState() => _TermsState();
}

class _TermsState extends State<_Terms> {
  late final _terms = TapGestureRecognizer()..onTap = () => context.push(Routes.terms);
  late final _privacy = TapGestureRecognizer()..onTap = () => context.push(Routes.privacy);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  void _tapAt(Offset at, TextSpan span, double width, TextScaler scaler, List<(int, int, VoidCallback)> links) {
    final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr, textScaler: scaler)
      ..layout(maxWidth: width);
    VoidCallback? best;
    var bestDistance = double.infinity;
    for (final (start, end, action) in links) {
      for (final b in painter.getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end))) {
        final r = b.toRect();
        final target = Rect.fromLTRB(r.left - 4, r.center.dy - 22, r.right + 4, r.center.dy + 22);
        final d = (r.center.dy - at.dy).abs();
        if (target.contains(at) && d < bestDistance) {
          best = action;
          bestDistance = d;
        }
      }
    }
    painter.dispose();
    best?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodySmall!
        .copyWith(fontSize: 12, height: 17 / 12, color: cs.onSurfaceVariant)
        .inter(FontWeight.w400);
    final link = base.copyWith(color: cs.primary).inter(FontWeight.w600);
    final parts = [
      tr('Davom etish orqali '),
      tr('Foydalanish shartlari'),
      tr(' va '),
      tr('Maxfiylik siyosati'),
      tr('ga rozilik bildirasiz.'),
    ];
    final span = TextSpan(
      style: base,
      children: [
        TextSpan(text: parts[0]),
        TextSpan(text: parts[1], style: link, recognizer: _terms),
        TextSpan(text: parts[2]),
        TextSpan(text: parts[3], style: link, recognizer: _privacy),
        TextSpan(text: parts[4]),
      ],
    );
    final termsAt = parts[0].length;
    final privacyAt = termsAt + parts[1].length + parts[2].length;
    final links = [
      (termsAt, termsAt + parts[1].length, () => context.push(Routes.terms)),
      (privacyAt, privacyAt + parts[3].length, () => context.push(Routes.privacy)),
    ];
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (d) => _tapAt(d.localPosition - const Offset(0, _Terms.pad), span, box.maxWidth, scaler, links),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _Terms.pad),
          child: Text.rich(span, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// Rings around the app icon, a turning sweep and two pulses spreading
/// out, faded by [show]; with [turn] stopped (reduced motion) only the rings.
class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.centre, required this.scale, required this.color, required this.show, required this.turn})
      : super(repaint: Listenable.merge([show, turn]));

  /// Radii and opacities, inner → outer (as on the splash).
  static const _rings = [(90.0, 0.30), (150.0, 0.20), (220.0, 0.13), (300.0, 0.08)];

  final Offset centre;
  final double scale;
  final Color color;
  final Animation<double> show, turn;

  @override
  void paint(Canvas canvas, Size size) {
    final v = Curves.easeOut.transform(show.value);
    if (v == 0) return;
    final outer = 300 * scale;

    if (turn.isAnimating) {
      final angle = turn.value * 2 * math.pi - math.pi / 2;
      canvas.drawCircle(
        centre,
        outer,
        Paint()
          ..shader = SweepGradient(
            // Bright leading edge, the tail behind it.
            colors: [color.withValues(alpha: 0), color.withValues(alpha: 0), color.withValues(alpha: 0.16 * v)],
            stops: const [0, 1 - 70 / 360, 1],
            transform: GradientRotation(angle),
          ).createShader(Rect.fromCircle(center: centre, radius: outer)),
      );
      for (final k in const [0.0, 0.5]) {
        final e = Curves.easeOut.transform((turn.value * 2 + k) % 1);
        canvas.drawCircle(
          centre,
          (66 + (300 - 66) * e) * scale,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color.withValues(alpha: 0.4 * (1 - e) * v),
        );
      }
    }

    for (final (r, a) in _rings) {
      canvas.drawCircle(
        centre,
        r * scale * (0.85 + 0.15 * v),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: a * v),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.centre != centre || old.scale != scale || old.color != color || old.show != show || old.turn != turn;
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: tc.warningContainer, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(Symbols.wifi_off_rounded, size: 20, color: tc.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('Internet yoʻq. Qayta urinib koʻring'),
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(fontSize: 14, height: 20 / 14, color: tc.warning)
                    .inter(FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
