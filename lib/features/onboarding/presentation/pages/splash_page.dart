import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/session/session.dart';

/// Brand splash; routes to onboarding, sign-in or the feed.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final _progress = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), _continue);
  }

  void _continue() {
    if (!mounted) return;
    _timer?.cancel();
    final session = getIt<Session>();
    context.go(session.signedIn ? Routes.home : (session.onboardingSeen ? Routes.signIn : Routes.onboarding));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    // Light: primary background; dark: deep surface with primary accents.
    final bg = dark ? cs.surface : cs.primary;
    final fg = dark ? cs.primary : cs.onPrimary;
    final ring = fg.withValues(alpha: 0.18);

    return Scaffold(
      backgroundColor: bg,
      body: Semantics(
        button: true,
        label: 'Davom etish',
        child: GestureDetector(
          onTap: _continue,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(520, ring),
              _ring(360, ring),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(28)),
                    child: Icon(Symbols.where_to_vote_rounded, size: 52, color: bg, fill: 1),
                  ),
                  const SizedBox(height: 20),
                  Text('Topildi',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: fg)),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Text(
                      'Topilgan buyum egasiga qaytadi',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, height: 1.45, color: fg.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    width: 120,
                    height: 4,
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (_, _) => LinearProgressIndicator(value: _progress.value, color: fg, backgroundColor: ring),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ring(double size, Color color) => IgnorePointer(
        child: OverflowBox(
          maxWidth: size,
          maxHeight: size,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color)),
          ),
        ),
      );
}
