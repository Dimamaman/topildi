import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/session/session.dart';
import '../../../../core/widgets/topildi_logo.dart';
import '../../../../core/l10n/tr.dart';

/// Brand splash; routes to onboarding, sign-in or the feed.
///
/// Continues the native launch screen (`flutter_native_splash` in
/// pubspec.yaml): the same brand blue in both themes and the same 70 pt
/// mark at the screen centre, so the hand-over doesn't show. The wordmark
/// and tagline then rise in under the mark.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// Mark height, matching `assets/brand/splash/*.png`.
  static const markHeight = 70.0;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), _continue);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intro.isDismissed) {
      MediaQuery.disableAnimationsOf(context) ? _intro.value = 1 : _intro.forward();
    }
  }

  void _continue() {
    if (!mounted) return;
    _timer?.cancel();
    final session = getIt<Session>();
    context.go(
      session.signedIn
          ? Routes.home
          : (session.onboardingSeen ? Routes.signIn : Routes.onboarding),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    final ring = fg.withValues(alpha: 0.18);
    // Text rises in over the first 400 ms; the bar fills over the whole run.
    final text = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.3, curve: Curves.easeOut),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: BrandColors.blue,
        body: Semantics(
          button: true,
          label: tr('Davom etish'),
          child: GestureDetector(
            onTap: _continue,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _ring(520, ring),
                _ring(360, ring),
                const TopildiMark(height: SplashPage.markHeight),
                // Below the centred mark.
                Positioned.fill(
                  top:
                      MediaQuery.sizeOf(context).height / 2 +
                      SplashPage.markHeight / 2 +
                      28,
                  child: AnimatedBuilder(
                    animation: text,
                    builder: (context, child) => Opacity(
                      opacity: text.value,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - text.value)),
                        child: child,
                      ),
                    ),
                    child: Column(
                      children: [
                        const TopildiWordmark(fontSize: 36, onDark: true),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Text(
                            tr('Topilgan buyum egasiga qaytadi'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.45,
                              color: fg.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      width: 120,
                      height: 4,
                      child: AnimatedBuilder(
                        animation: _intro,
                        builder: (_, _) => LinearProgressIndicator(
                          value: _intro.value,
                          color: fg,
                          backgroundColor: ring,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
      ),
    ),
  );
}
