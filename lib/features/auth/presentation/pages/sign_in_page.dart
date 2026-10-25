import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../cubit/sign_in_cubit.dart';
import '../widgets/phone_formatter.dart';
import '../../../../core/l10n/tr.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<SignInCubit>(), child: const _SignInView());
  }
}

const _side = 24.0;
const _anim = Duration(milliseconds: 200);

/// Kirish, iOS 26 style: centred logo and title, capsule phone field,
/// capsule "Kodni olish" and a glass Google button; terms at the bottom.
/// While the keyboard is up the header compacts (logo 64 → 48, title
/// 34 → 28) and the page scrolls so the button stays above the keyboard.
class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  final _buttonKey = GlobalKey();
  bool _keyboard = false;

  /// Brings "Kodni olish" into view once the keyboard has opened.
  void _revealButton() => WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = _buttonKey.currentContext;
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(
        ctx,
        duration: _anim,
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<SignInCubit>();
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (keyboard && !_keyboard) _revealButton();
    _keyboard = keyboard;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: BlocConsumer<SignInCubit, SignInState>(
        listenWhen: (a, b) => b.next != SignInNext.none || (b.failure != null && a.failure != b.failure),
        listener: (context, state) {
          switch (state.next) {
            case SignInNext.code:
              context.push(Routes.signInCode, extra: state.phone);
            case SignInNext.profile:
              context.go(Routes.profileSetup);
            case SignInNext.home:
              context.go(Routes.home);
            case SignInNext.none:
              final f = state.failure;
              // A cancelled Google sheet comes back without a message: stay quiet.
              if (f is ValidationFailure && f.message == null) return;
              TFeedback.error(
                context,
                switch (f) {
                  NetworkFailure() => tr('Internet yoʻq. Qayta urinib koʻring'),
                  ValidationFailure(:final message?) => message,
                  _ => tr('Kirishda xatolik yuz berdi'),
                },
              );
          }
        },
        builder: (context, state) {
          final linkStyle = text.bodySmall!.copyWith(color: cs.primary).inter(FontWeight.w600);
          return Scaffold(
            // Bottom inset ignored: the terms sit 40 above the screen edge, as designed.
            body: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(_side, keyboard ? 16 : 66, _side, keyboard ? 16 : 40),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight - (keyboard ? 32 : 106)),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: _Logo(compact: keyboard)),
                          SizedBox(height: keyboard ? 16 : 24),
                          Semantics(
                            header: true,
                            child: AnimatedDefaultTextStyle(
                              duration: _anim,
                              textAlign: TextAlign.center,
                              style: text.headlineMedium!
                                  .copyWith(
                                    fontSize: keyboard ? 28 : 34,
                                    height: keyboard ? 34 / 28 : 41 / 34,
                                    letterSpacing: keyboard ? -0.5 : -0.7,
                                  )
                                  .inter(FontWeight.w700),
                              child: Text(tr('Xush kelibsiz!'), textAlign: TextAlign.center),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              tr('Telefon raqamingizni kiriting, sizga SMS kod yuboramiz.'),
                              textAlign: TextAlign.center,
                              style: text.bodyLarge!
                                  .copyWith(fontSize: 17, height: 24 / 17, color: cs.secondary)
                                  .inter(FontWeight.w400),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _PhoneField(error: state.error, onChanged: cubit.setInput, onSubmitted: cubit.requestCode),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Icon(Symbols.lock_rounded, size: 15, fill: 1, color: cs.primary),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tr('Raqamingiz boshqa foydalanuvchilarga hech qachon koʻrsatilmaydi.'),
                                    style: text.bodySmall!
                                        .copyWith(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant)
                                        .inter(FontWeight.w400),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          KeyedSubtree(
                            key: _buttonKey,
                            child: _PrimaryButton(
                              label: tr('Kodni olish'),
                              // Dimmed until the number is complete; a tap still
                              // validates so the reason shows under the field.
                              ready: state.phone != null,
                              loading: state.loading,
                              onTap: cubit.requestCode,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _OrDivider(),
                          const SizedBox(height: 18),
                          _GoogleButton(onTap: state.loading ? null : cubit.google),
                          const Spacer(),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32 - _side),
                            child: Text.rich(
                              TextSpan(
                                style: text.bodySmall!
                                    .copyWith(fontSize: 13, height: 19 / 13, color: cs.onSurfaceVariant)
                                    .inter(FontWeight.w400),
                                children: [
                                  TextSpan(text: tr('Davom etish orqali ')),
                                  TextSpan(
                                    text: tr('Foydalanish shartlari'),
                                    style: linkStyle,
                                    recognizer: TapGestureRecognizer()..onTap = () => context.push(Routes.terms),
                                  ),
                                  TextSpan(text: tr(' va ')),
                                  TextSpan(
                                    text: tr('Maxfiylik siyosati'),
                                    style: linkStyle,
                                    recognizer: TapGestureRecognizer()..onTap = () => context.push(Routes.privacy),
                                  ),
                                  TextSpan(text: tr('ga rozilik bildirasiz.')),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 64×64 (48 while typing) rounded primary square with the pin-check mark.
class _Logo extends StatelessWidget {
  const _Logo({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = compact ? 48.0 : 64.0;
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: _anim,
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(compact ? 16 : 22),
          boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), offset: const Offset(0, 10), blurRadius: 30)],
        ),
        child: Icon(Symbols.where_to_vote_rounded, size: compact ? 26 : 34, fill: 1, color: cs.onPrimary),
      ),
    );
  }
}

/// "TELEFON RAQAM" label + 58px capsule: "+998" pill and the formatted
/// number. 1px outline-variant at rest, 2px primary when focused, 2px
/// error with the message below when invalid.
class _PhoneField extends StatefulWidget {
  const _PhoneField({required this.error, required this.onChanged, required this.onSubmitted});

  final String? error;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final error = widget.error;
    final (borderColor, borderWidth) = error != null
        ? (cs.error, 2.0)
        : _focus.hasFocus
        ? (cs.primary, 2.0)
        : (cs.outlineVariant, 1.0);
    final style = text.bodyLarge!
        .copyWith(fontSize: 18, height: 24 / 18, letterSpacing: 0.3, color: cs.onSurface)
        .inter(FontWeight.w400);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            tr('Telefon raqam').toUpperCase(),
            style: text.labelMedium!
                .copyWith(fontSize: 13, height: 18 / 13, letterSpacing: 0.2, color: cs.onSurfaceVariant)
                .inter(FontWeight.w400),
          ),
        ),
        GestureDetector(
          onTap: _focus.requestFocus,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.only(left: 8, right: 20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(999),
              // Drawn inside, so the field doesn't shift when the width changes.
              border: Border.all(color: borderColor, width: borderWidth, strokeAlign: BorderSide.strokeAlignInside),
            ),
            child: Row(
              children: [
                // Only Uzbekistan for now, so not tappable.
                Container(
                  constraints: const BoxConstraints(minHeight: 42),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: context.glass.quiet, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    '+998',
                    style: text.bodyLarge!
                        .copyWith(fontSize: 17, height: 22 / 17, color: cs.onSurface)
                        .inter(FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    focusNode: _focus,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, UzPhoneFormatter()],
                    onChanged: widget.onChanged,
                    onSubmitted: (_) => widget.onSubmitted(),
                    style: style,
                    cursorColor: cs.primary,
                    // The capsule draws the border; switch off every themed one.
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 17),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: '90 123 45 67',
                      hintStyle: style.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: text.bodySmall!.copyWith(fontSize: 13, height: 18 / 13, color: cs.error).inter(FontWeight.w500),
              ),
            ),
          ),
      ],
    );
  }
}

/// 56px primary capsule; 0.45 opacity until [ready], white spinner while [loading].
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.ready, required this.loading, required this.onTap});

  final String label;
  final bool ready, loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: ready && !loading,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: _anim,
          opacity: ready ? 1 : 0.45,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(999)),
            child: loading
                ? CupertinoActivityIndicator(color: cs.onPrimary)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge!
                          .copyWith(fontSize: 17, height: 22 / 17, color: cs.onPrimary)
                          .inter(FontWeight.w600),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final line = Expanded(child: Container(height: 0.5, color: context.ts.separator));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            tr('yoki'),
            style: Theme.of(context).textTheme.bodySmall!
                .copyWith(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant)
                .inter(FontWeight.w400),
          ),
        ),
        line,
      ],
    );
  }
}

/// 56px glass capsule: grey circle with "G" + "Google orqali davom etish".
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final label = tr('Google orqali davom etish');
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 56,
          child: GlassSurface(
            color: context.glass.button,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dark ? cs.onSurface : cs.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'G',
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dark ? cs.surface : cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge!
                          .copyWith(fontSize: 17, height: 22 / 17, color: cs.onSurface)
                          .inter(FontWeight.w600),
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
}
