import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/session/session.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../widgets/onboarding_art.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/topildi_theme.dart';

/// Room kept free at the bottom for the dots and the button (20 + 8 + 20 + 56).
const _bottomBar = 104.0;

/// Three-slide intro shown on first launch. iOS 26 style: soft blue light,
/// a glass scene per slide, a two-line title (second line in primary), the
/// dots centred above a full-width capsule button.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  int _index = 0;

  static List<(String, String)> get _slides => [
    (
      tr('Nimadir topdingizmi?'),
      tr('Rasmga oling va eʼlon bering. Egasi sizni ilova orqali topadi, raqamingiz koʻrinmaydi.'),
    ),
    (
      tr('Nimadir yoʻqotdingizmi?'),
      tr('Lentadan qidiring yoki “Yoʻqolgan” eʼlonini bering. Yangi mos eʼlon chiqsa, sizga xabar beramiz.'),
    ),
    (
      tr('Xavfsiz qaytaring'),
      tr('Egasi faqat siz bilgan yashirin belgini toʻgʻri aytsa, buyumni topshirasiz. Firibgarlarga yoʻl yoʻq.'),
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  void _finish() {
    getIt<Session>().markOnboardingSeen();
    context.go(Routes.signIn);
  }

  void _next() =>
      _isLast ? _finish() : _pages.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pad = MediaQuery.paddingOf(context);
    final bottom = pad.bottom > 0 ? pad.bottom : 34.0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: _Background(dark: dark)),
            PageView.builder(
              controller: _pages,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _Slide(
                index: i,
                active: i == _index,
                title: _slides[i].$1,
                body: _slides[i].$2,
                pages: _pages,
                top: pad.top + 62,
                bottom: bottom + _bottomBar + 24,
              ),
            ),
            // Oʻtkazib yuborish — slides 1 and 2 only.
            Positioned(
              right: 16,
              top: pad.top - 3,
              child: AnimatedOpacity(
                opacity: _isLast ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: IgnorePointer(
                  ignoring: _isLast,
                  child: _SkipButton(onTap: _finish),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dots(index: _index, count: _slides.length),
                  const SizedBox(height: 20),
                  _CtaButton(
                    label: _isLast ? tr('Boshlash') : tr('Keyingi'),
                    icon: _isLast ? null : Symbols.arrow_forward_rounded,
                    onTap: _next,
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

/// `surface` with a soft #e3ebfc light from the top centre.
class _Background extends StatelessWidget {
  const _Background({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF000000) : const Color(0xFFF4F6FA),
        // CSS `circle at 50% 0%` to 50% of the farthest corner (≈433 on 390×844).
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.11,
          colors: dark ? const [Color(0xFF0A1430), Color(0x000A1430)] : const [Color(0xFFE3EBFC), Color(0x00E3EBFC)],
        ),
      ),
    );
  }
}

/// Scene, then the two-line title and body. The scene shrinks (down to
/// whatever fits) so text and button never overlap on small phones.
class _Slide extends StatelessWidget {
  const _Slide({
    required this.index,
    required this.active,
    required this.title,
    required this.body,
    required this.pages,
    required this.top,
    required this.bottom,
  });

  final int index;
  final bool active;
  final String title, body;
  final PageController pages;
  final double top, bottom;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final still = MediaQuery.disableAnimationsOf(context);
    final small = MediaQuery.sizeOf(context).height < 700;
    // Title in two lines: the first word, then the rest in primary.
    final split = title.indexOf(' ');
    final (first, second) = split < 0 ? (title, '') : (title.substring(0, split), title.substring(split + 1));
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: OnboardingArt.height * (small ? 0.8 : 1)),
              child: AnimatedBuilder(
                animation: pages,
                builder: (context, child) {
                  // Parallax: the scene trails the page by 16px and fades.
                  final page = pages.hasClients && pages.position.haveDimensions ? pages.page! : index.toDouble();
                  final d = (page - index).clamp(-1.0, 1.0);
                  return Opacity(
                    opacity: (1 - d.abs()).clamp(0.0, 1.0),
                    child: Transform.translate(offset: Offset(still ? 0 : d * 16, 0), child: child),
                  );
                },
                child: FittedBox(
                  child: OnboardingArt(index: index, active: active),
                ),
              ),
            ),
          ),
          SizedBox(height: small ? 24 : 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: first),
                      if (second.isNotEmpty)
                        TextSpan(
                          text: '\n$second',
                          style: TextStyle(color: cs.primary),
                        ),
                    ],
                  ),
                  style: text.displaySmall!
                      .copyWith(fontSize: 36, height: 40 / 36, letterSpacing: -1.2, color: cs.onSurface)
                      .inter(FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: text.bodyLarge!
                      .copyWith(fontSize: 16, height: 23 / 16, color: cs.secondary)
                      .inter(FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass "Oʻtkazib yuborish" capsule, 40 tall inside a 44 tap target.
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: tr('Oʻtkazib yuborish'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SizedBox(
            height: 40,
            child: GlassSurface(
              color: dark ? const Color(0xE616171A) : const Color(0xCCFFFFFF),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  tr('Oʻtkazib yuborish'),
                  maxLines: 1,
                  textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
                  style: TextStyle(fontSize: 15, color: cs.secondary).inter(FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width 56 primary capsule: "Keyingi →" / "Boshlash".
class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.onTap, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: context.primaryGlow(0.28), blurRadius: 28, offset: const Offset(0, 12)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
                  style: TextStyle(fontSize: 17, height: 22 / 17, color: cs.onPrimary).inter(FontWeight.w600),
                ),
              ),
              if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20, color: cs.onPrimary)],
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.count});

  final int index, count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: tr('{i}-sahifa, jami {count}', {'i': index + 1, 'count': count}),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: i == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? cs.primary : (dark ? const Color(0xFF26282D) : const Color(0xFFD3D9E4)),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
