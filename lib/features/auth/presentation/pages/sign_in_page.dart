import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/t_button.dart';
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

class _SignInView extends StatelessWidget {
  const _SignInView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<SignInCubit>();

    return BlocConsumer<SignInCubit, SignInState>(
      listenWhen: (a, b) => b.next != SignInNext.none || (b.failure != null && a.failure != b.failure),
      listener: (context, state) {
        switch (state.next) {
          case SignInNext.code:
            context.push(Routes.signInCode, extra: state.phone);
          case SignInNext.profile:
            context.go(Routes.profileSetup);
          case SignInNext.none:
            TFeedback.error(
              context,
              state.failure is NetworkFailure ? tr('Internet yoʻq. Qayta urinib koʻring') : tr('Kirishda xatolik yuz berdi'),
            );
        }
      },
      builder: (context, state) {
        final error = state.error;
        final linkStyle = TextStyle(color: cs.primary, fontWeight: FontWeight.w600);
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(TSpace.xl, TSpace.xl, TSpace.xl, TSpace.x2l),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - TSpace.xl - TSpace.x2l),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: TSpace.x4l),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(TRadius.lg)),
                            child: Icon(Symbols.where_to_vote_rounded, color: cs.onPrimary, size: 30, fill: 1),
                          ),
                        ),
                        const SizedBox(height: TSpace.lg),
                        Text(tr('Xush kelibsiz!'), style: text.headlineMedium),
                        const SizedBox(height: TSpace.xs),
                        Text(tr('Telefon raqamingizni kiriting, sizga SMS kod yuboramiz.'),
                            style: text.bodyLarge!.copyWith(color: cs.secondary)),
                        const SizedBox(height: TSpace.x2l),
                        Text(tr('Telefon raqam'), style: text.labelLarge!.copyWith(color: error != null ? cs.error : null)),
                        const SizedBox(height: TSpace.xs),
                        TextField(
                          autofocus: true,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumberNational],
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, UzPhoneFormatter()],
                          onChanged: cubit.setInput,
                          onSubmitted: (_) => cubit.requestCode(),
                          style: const TextStyle(fontSize: 17, letterSpacing: 0.34),
                          decoration: InputDecoration(
                            hintText: '90 123 45 67',
                            errorText: error,
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('+998', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  Container(width: 1, height: 24, color: cs.outlineVariant),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: TSpace.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Symbols.lock_rounded, size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: TSpace.xs),
                            Expanded(
                              child: Text(
                                tr('Raqamingiz boshqa foydalanuvchilarga hech qachon koʻrsatilmaydi.'),
                                style: TextStyle(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TSpace.xl),
                        TButton.primary(label: tr('Kodni olish'), loading: state.loading, onPressed: cubit.requestCode),
                        const SizedBox(height: TSpace.md),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: TSpace.sm),
                              child: Text('yoki', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: TSpace.md),
                        TButton.google(onPressed: state.loading ? null : cubit.google),
                        const Spacer(),
                        const SizedBox(height: TSpace.xl),
                        Text.rich(
                          TextSpan(
                            style: TextStyle(fontSize: 13, height: 19 / 13, color: cs.onSurfaceVariant),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
