import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

/// Kirish, iOS 26 style: centred logo and title, capsule "Telegram orqali
/// kirish" and a glass Google button; terms at the bottom. Telegram opens
/// the bot, where the number is shared with one tap (no SMS code).
class _SignInView extends StatelessWidget {
  const _SignInView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<SignInCubit>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: BlocConsumer<SignInCubit, SignInState>(
        listenWhen: (a, b) => b.next != SignInNext.none || (b.failure != null && a.failure != b.failure),
        listener: (context, state) {
          switch (state.next) {
            case SignInNext.telegram:
              context.push(Routes.signInTelegram, extra: state.login);
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
                  // Debug builds also show the cause (e.g. a Firebase Auth error code).
                  _ when kDebugMode && f?.message != null => '${tr('Kirishda xatolik yuz berdi')}\n${f!.message}',
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
                  padding: const EdgeInsets.fromLTRB(_side, 66, _side, 40),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight - 106),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: _Logo()),
                          const SizedBox(height: 24),
                          Semantics(
                            header: true,
                            child: Text(
                              tr('Xush kelibsiz!'),
                              textAlign: TextAlign.center,
                              style: text.headlineMedium!
                                  .copyWith(fontSize: 34, height: 41 / 34, letterSpacing: -0.7)
                                  .inter(FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              tr('Telegram orqali kiring: raqamingizni botga bir bosishda ulashasiz, SMS kod kerak emas.'),
                              textAlign: TextAlign.center,
                              style: text.bodyLarge!
                                  .copyWith(fontSize: 17, height: 24 / 17, color: cs.secondary)
                                  .inter(FontWeight.w400),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _PrimaryButton(
                            label: tr('Telegram orqali kirish'),
                            icon: Symbols.send_rounded,
                            ready: true,
                            loading: state.loading,
                            onTap: cubit.telegram,
                          ),
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

/// 64×64 rounded primary square with the pin-check mark.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), offset: const Offset(0, 10), blurRadius: 30)],
        ),
        child: Icon(Symbols.where_to_vote_rounded, size: 34, fill: 1, color: cs.onPrimary),
      ),
    );
  }
}

/// 56px primary capsule; 0.45 opacity until [ready], white spinner while [loading].
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.icon, required this.ready, required this.loading, required this.onTap});

  final String label;
  final IconData? icon;
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[Icon(icon, size: 20, fill: 1, color: cs.onPrimary), const SizedBox(width: 10)],
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
