import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/session/session.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/t_button.dart';
import '../widgets/onboarding_art.dart';
import '../../../../core/l10n/tr.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pages = PageController();
  int _index = 0;

  static List<(String, String)> get _slides => [
    (tr('Nimadir topdingizmi?'), tr('Rasmga oling va eʼlon bering. Egasi sizni ilova orqali topadi, raqamingiz koʻrinmaydi.')),
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
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(TSpace.xl, TSpace.xs, TSpace.xl, TSpace.x2l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: IgnorePointer(
                      ignoring: _isLast,
                      child: TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          overlayColor: Colors.transparent,
                          foregroundColor: cs.onSurfaceVariant,
                        ),
                        child: Text(tr('Oʻtkazib yuborish'), style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Center(
                          child: FittedBox(child: OnboardingArt(index: i)),
                        ),
                      ),
                      Text(_slides[i].$1, style: text.headlineMedium!.copyWith(letterSpacing: -0.28)),
                      const SizedBox(height: TSpace.sm),
                      Text(
                        _slides[i].$2,
                        style: text.bodyLarge!.copyWith(fontSize: 17, height: 26 / 17, color: cs.secondary),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
              if (_isLast) ...[
                _Dots(index: _index, count: _slides.length, center: true),
                const SizedBox(height: TSpace.lg),
                TButton.primary(label: tr('Boshlash'), onPressed: _finish),
              ] else
                Row(
                  children: [
                    _Dots(index: _index, count: _slides.length),
                    const Spacer(),
                    TButton.primary(
                      label: tr('Keyingi'),
                      icon: Symbols.arrow_forward_rounded,
                      expand: false,
                      onPressed: _next,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.count, this.center = false});

  final int index, count;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: tr('{i}-sahifa, jami {count}', {'i': index + 1, 'count': count}),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == index ? cs.primary : cs.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
