import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_top_bar.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/usecases/verify_sms_code.dart';
import '../cubit/sms_code_cubit.dart';
import '../../../../core/l10n/tr.dart';

class SmsCodePage extends StatelessWidget {
  const SmsCodePage({super.key, required this.phone});

  final PhoneNumber phone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SmsCodeCubit>()..start(phone),
      child: _SmsCodeView(phone: phone),
    );
  }
}

class _SmsCodeView extends StatefulWidget {
  const _SmsCodeView({required this.phone});

  final PhoneNumber phone;

  @override
  State<_SmsCodeView> createState() => _SmsCodeViewState();
}

class _SmsCodeViewState extends State<_SmsCodeView> {
  // One hidden field drives the six boxes: works with paste and SMS autofill.
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<SmsCodeCubit>();

    return BlocConsumer<SmsCodeCubit, SmsCodeState>(
      listenWhen: (a, b) => b.verified && !a.verified,
      listener: (context, _) => context.go(Routes.profileSetup),
      builder: (context, state) {
        final secs = state.seconds.toString().padLeft(2, '0');
        return Scaffold(
          appBar: const TTopBar(),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(TSpace.xl, TSpace.md, TSpace.xl, TSpace.x2l),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - TSpace.md - TSpace.x2l),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(tr('Kodni kiriting'), style: text.headlineMedium),
                        const SizedBox(height: TSpace.xs),
                        Text.rich(
                          TextSpan(
                            style: text.bodyLarge!.copyWith(color: cs.secondary),
                            children: [
                              TextSpan(
                                text: widget.phone.masked,
                                style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
                              ),
                              TextSpan(text: tr(' raqamiga 6 xonali kod yubordik.')),
                            ],
                          ),
                        ),
                        const SizedBox(height: TSpace.x2l),
                        Semantics(
                          label: tr('SMS kod'),
                          textField: true,
                          child: GestureDetector(
                            onTap: _focus.requestFocus,
                            child: Stack(
                              children: [
                                // Invisible input that receives keystrokes.
                                Opacity(
                                  opacity: 0,
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focus,
                                    autofocus: true,
                                    keyboardType: TextInputType.number,
                                    autofillHints: const [AutofillHints.oneTimeCode],
                                    maxLength: VerifySmsCode.codeLength,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: cubit.setCode,
                                    showCursor: false,
                                    decoration: const InputDecoration(counterText: ''),
                                  ),
                                ),
                                Row(
                                  children: [
                                    for (var i = 0; i < VerifySmsCode.codeLength; i++) ...[
                                      if (i > 0) const SizedBox(width: TSpace.xs),
                                      Expanded(child: _Box(index: i, code: state.code, focused: _focus.hasFocus, error: state.error != null)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: TSpace.sm),
                          Text(state.error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: cs.error)),
                        ],
                        const SizedBox(height: TSpace.lg),
                        SizedBox(
                          height: TSize.tapTarget,
                          child: Center(
                            child: state.seconds > 0
                                ? Text.rich(
                                    TextSpan(
                                      style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
                                      children: [
                                        TextSpan(text: tr('Kodni qayta yuborish: ')),
                                        TextSpan(
                                          text: '0:$secs',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurface,
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : TButton.text(label: tr('Kodni qayta yuborish'), onPressed: cubit.resend),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: TSpace.xl),
                        TButton.primary(
                          label: tr('Tasdiqlash'),
                          loading: state.verifying,
                          onPressed: state.code.length == VerifySmsCode.codeLength ? cubit.verify : null,
                        ),
                        const SizedBox(height: TSpace.xs),
                        TButton.text(label: tr('Raqamni oʻzgartirish'), expand: true, onPressed: () => context.pop()),
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

class _Box extends StatelessWidget {
  const _Box({required this.index, required this.code, required this.focused, required this.error});

  final int index;
  final String code;
  final bool focused, error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filled = index < code.length;
    final active = focused && index == code.length.clamp(0, VerifySmsCode.codeLength - 1);
    final borderColor = error ? cs.error : (active ? cs.primary : (filled ? cs.outline : cs.outlineVariant));
    return ExcludeSemantics(
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(TRadius.md),
          border: Border.all(color: borderColor, width: active || error ? 2 : 1),
        ),
        child: Text(
          filled ? code[index] : '',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
