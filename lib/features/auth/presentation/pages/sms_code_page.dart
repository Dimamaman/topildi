import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/glass_surface.dart';
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

const _side = 20.0;
const _len = VerifySmsCode.codeLength;
const _anim = Duration(milliseconds: 200);

/// Where the ring and cells are in their life cycle; drives their colours.
enum _Tone { normal, success, error }

/// SMS kod, "lock ring" style: a ring of six segments around a lock fills
/// one segment per digit; the six capsule cells below mirror the code.
/// Correct → everything turns green and the lock opens; wrong → red, the
/// cells shake and clear.
class _SmsCodeView extends StatefulWidget {
  const _SmsCodeView({required this.phone});

  final PhoneNumber phone;

  @override
  State<_SmsCodeView> createState() => _SmsCodeViewState();
}

class _SmsCodeViewState extends State<_SmsCodeView> with SingleTickerProviderStateMixin {
  // One hidden field drives the six cells: works with paste and SMS autofill.
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _buttonKey = GlobalKey();
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  _Tone _tone = _Tone.normal;
  bool _keyboard = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final cubit = context.read<SmsCodeCubit>();
    if (v.length > cubit.state.code.length) HapticFeedback.selectionClick();
    if (_tone == _Tone.error) setState(() => _tone = _Tone.normal);
    cubit.setCode(v);
  }

  Future<void> _paste(Offset at) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (!mounted || digits.isEmpty) return;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final picked = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromRect(at & Size.zero, Offset.zero & overlay.size),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [PopupMenuItem(value: true, height: 44, child: Text(tr('Qoʻyish')))],
    );
    if (picked != true || !mounted) return;
    final code = digits.substring(0, math.min(_len, digits.length));
    _controller.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    _onChanged(code);
  }

  /// Brings "Tasdiqlash" into view once the keyboard has opened.
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

  Future<void> _onResult(BuildContext context, SmsCodeState state) async {
    final cubit = context.read<SmsCodeCubit>();
    if (state.verified) {
      setState(() => _tone = _Tone.success);
      HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (context.mounted) context.go(Routes.profileSetup);
      return;
    }
    // A wrong code (not a network problem): red, shake, then clear.
    setState(() => _tone = _Tone.error);
    HapticFeedback.heavyImpact();
    await _shake.forward(from: 0);
    if (!mounted) return;
    _controller.clear();
    cubit.clearCode();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<SmsCodeCubit>();
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (keyboard && !_keyboard) _revealButton();
    _keyboard = keyboard;
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: BlocConsumer<SmsCodeCubit, SmsCodeState>(
        listenWhen: (a, b) =>
            (b.verified && !a.verified) || (b.error != null && a.error != b.error && !b.offline && !b.verifying),
        listener: _onResult,
        builder: (context, state) {
          final secs = state.seconds.toString().padLeft(2, '0');
          final accent = switch (_tone) {
            _Tone.success => tc.success,
            _Tone.error => cs.error,
            _Tone.normal => cs.primary,
          };
          final ready = state.code.length == _len;
          return Scaffold(
            body: Column(
              children: [
                SizedBox(height: top < 30 ? top + 8 : top),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _GlassBack(onTap: () => context.pop()),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        _side,
                        keyboard ? 4 : 12,
                        _side,
                        keyboard ? 16 : math.max(34, MediaQuery.paddingOf(context).bottom),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              c.maxHeight - (keyboard ? 20 : 12 + math.max(34, MediaQuery.paddingOf(context).bottom)),
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: _LockRing(
                                  filled: state.code.length,
                                  accent: accent,
                                  tone: _tone,
                                  spinning: state.verifying,
                                  size: keyboard ? 120 : 200,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Semantics(
                                header: true,
                                child: AnimatedDefaultTextStyle(
                                  duration: _anim,
                                  textAlign: TextAlign.center,
                                  style: text.headlineMedium!
                                      .copyWith(
                                        fontSize: keyboard ? 26 : 30,
                                        height: keyboard ? 32 / 26 : 36 / 30,
                                        letterSpacing: -0.5,
                                      )
                                      .inter(FontWeight.w700),
                                  child: Text(tr('Kodni kiriting'), textAlign: TextAlign.center),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text.rich(
                                  TextSpan(
                                    style: text.bodyLarge!
                                        .copyWith(fontSize: 16, height: 22 / 16, color: cs.secondary)
                                        .inter(FontWeight.w400),
                                    children: [
                                      TextSpan(
                                        text: widget.phone.masked,
                                        style: text.bodyLarge!
                                            .copyWith(fontSize: 16, height: 22 / 16, color: cs.onSurface)
                                            .inter(FontWeight.w600),
                                      ),
                                      TextSpan(
                                        text: tr(
                                          ' raqamiga 6 xonali kod yubordik. Har bir raqam qulfning bir boʻlagini ochadi.',
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (state.offline) ...[const SizedBox(height: 16), const _OfflineBanner()],
                              const SizedBox(height: 24),
                              _Cells(
                                controller: _controller,
                                focus: _focus,
                                code: state.code,
                                accent: accent,
                                enabled: !state.verifying && _tone != _Tone.success,
                                shake: _shake,
                                onChanged: _onChanged,
                                onSubmitted: cubit.verify,
                                onPaste: _paste,
                              ),
                              if (state.error != null && !state.offline) ...[
                                const SizedBox(height: 12),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    state.error!,
                                    textAlign: TextAlign.center,
                                    style: text.bodySmall!
                                        .copyWith(fontSize: 14, height: 20 / 14, color: cs.error)
                                        .inter(FontWeight.w500),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18 - 12),
                              _Resend(seconds: state.seconds, secs: secs, onResend: cubit.resend),
                              const Spacer(),
                              const SizedBox(height: 24),
                              KeyedSubtree(
                                key: _buttonKey,
                                child: _PrimaryButton(
                                  label: tr('Tasdiqlash'),
                                  ready: ready,
                                  loading: state.verifying,
                                  onTap: ready ? cubit.verify : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _LinkButton(label: tr('Raqamni oʻzgartirish'), onTap: () => context.pop()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GlassBack extends StatelessWidget {
  const _GlassBack({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tr('Orqaga'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: 44,
          child: GlassSurface(
            child: Icon(Symbols.chevron_left_rounded, size: 24, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// 200×200 (120 while typing) ring of six segments around a white disc
/// holding the lock. Segments fill one per digit (220ms, drawn from start
/// to end); the whole ring spins slowly while the code is checked.
class _LockRing extends StatefulWidget {
  const _LockRing({
    required this.filled,
    required this.accent,
    required this.tone,
    required this.spinning,
    required this.size,
  });

  final int filled;
  final Color accent;
  final _Tone tone;
  final bool spinning;
  final double size;

  @override
  State<_LockRing> createState() => _LockRingState();
}

class _LockRingState extends State<_LockRing> with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _spin.repeat();
  }

  @override
  void didUpdateWidget(_LockRing old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.spinning && _spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final success = widget.tone == _Tone.success;
    // Full while checking or after success; otherwise one segment per digit.
    final target = widget.spinning || success ? _len.toDouble() : widget.filled.toDouble();
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: _anim,
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size,
        child: FittedBox(
          child: SizedBox.square(
            dimension: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _spin,
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: widget.accent),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, color, _) => TweenAnimationBuilder<double>(
                      tween: Tween(end: target),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      builder: (context, progress, _) => CustomPaint(
                        size: const Size.square(200),
                        painter: _RingPainter(progress: progress, track: cs.outlineVariant, fill: color!),
                      ),
                    ),
                  ),
                ),
                // White disc, 34 inside the ring's outer edge.
                Container(
                  width: 132,
                  height: 132,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dark ? Colors.black.withValues(alpha: 0.45) : cs.primary.withValues(alpha: 0.18),
                        offset: const Offset(0, 14),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: success ? tc.successContainer : cs.primaryContainer,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Icon(
                      success ? Symbols.lock_open_rounded : Symbols.lock_rounded,
                      size: 44,
                      fill: 1,
                      color: success ? tc.success : (dark ? cs.onPrimaryContainer : cs.primary),
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

/// Six round-capped arcs, radius 86, 12 thick. Each 60° slot holds a 40°
/// arc (≈72px with the caps) and an ≈18px gap; the first starts at −82°.
/// [progress] 0…6: segment i is drawn up to `progress − i` of its length.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.track, required this.fill});

  final double progress;
  final Color track, fill;

  static const _radius = 86.0, _stroke = 12.0;
  static const _slot = math.pi / 3, _sweep = 40 * math.pi / 180, _start = -82 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: _radius);
    Paint paint(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = c;
    for (var i = 0; i < _len; i++) {
      final start = _start + i * _slot;
      final p = (progress - i).clamp(0.0, 1.0);
      if (p < 1) canvas.drawArc(rect, start, _sweep, false, paint(track));
      if (p > 0) canvas.drawArc(rect, start, _sweep * p, false, paint(fill));
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.track != track || old.fill != fill;
}

/// Six 46×56 capsules over one hidden field. Filled: accent with the digit
/// in white; current: 2px accent ring with a blinking cursor; empty: 1px
/// outline-variant. Shakes when [shake] runs.
class _Cells extends StatelessWidget {
  const _Cells({
    required this.controller,
    required this.focus,
    required this.code,
    required this.accent,
    required this.enabled,
    required this.shake,
    required this.onChanged,
    required this.onSubmitted,
    required this.onPaste,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String code;
  final Color accent;
  final bool enabled;
  final Animation<double> shake;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final ValueChanged<Offset> onPaste;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tr('6 xonali kod, {n} ta kiritildi', {'n': code.length}),
      textField: true,
      child: GestureDetector(
        onTap: enabled ? focus.requestFocus : null,
        onLongPressStart: enabled ? (d) => onPaste(d.globalPosition) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: shake,
          // Three left-right swings that die out.
          builder: (context, child) => Transform.translate(
            offset: Offset(math.sin(shake.value * math.pi * 6) * 10 * (1 - shake.value), 0),
            child: child,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Invisible input that receives keystrokes and SMS autofill.
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    autofocus: true,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: _len,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: onChanged,
                    onSubmitted: (_) => onSubmitted(),
                    showCursor: false,
                    enableInteractiveSelection: false,
                    decoration: const InputDecoration(counterText: '', border: InputBorder.none, filled: false),
                  ),
                ),
              ),
              ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _len; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _Cell(
                          digit: i < code.length ? code[i] : null,
                          active: focus.hasFocus && enabled && i == code.length,
                          accent: accent,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.digit, required this.active, required this.accent});

  final String? digit;
  final bool active;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filled = digit != null;
    // Digits sit on the accent; on dark that is a light blue, so they turn dark.
    final onAccent = Theme.of(context).brightness == Brightness.dark ? cs.surface : cs.onPrimary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 46,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? accent : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: filled
            ? null
            : Border.all(
                color: active ? accent : cs.outlineVariant,
                width: active ? 2 : 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
      ),
      child: filled
          ? Text(
              digit!,
              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
              style: Theme.of(context).textTheme.headlineSmall!
                  .copyWith(
                    fontSize: 26,
                    height: 1,
                    color: onAccent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )
                  .inter(FontWeight.w700),
            )
          : active
          ? _Cursor(color: accent)
          : null,
    );
  }
}

/// 2×24 blinking caret.
class _Cursor extends StatefulWidget {
  const _Cursor({required this.color});

  final Color color;

  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> {
  bool _on = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 530), (_) => setState(() => _on = !_on));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _on ? 1 : 0,
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(1)),
      ),
    );
  }
}

/// "Kodni qayta yuborish · 0:38" while counting; a primary link after.
class _Resend extends StatelessWidget {
  const _Resend({required this.seconds, required this.secs, required this.onResend});

  final int seconds;
  final String secs;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14, height: 20 / 14);
    return SizedBox(
      height: 44,
      child: Center(
        child: seconds > 0
            ? Text.rich(
                TextSpan(
                  style: base.copyWith(color: cs.onSurfaceVariant).inter(FontWeight.w400),
                  children: [
                    TextSpan(text: tr('Kodni qayta yuborish · ')),
                    TextSpan(
                      text: '0:$secs',
                      style: base
                          .copyWith(color: cs.onSurface, fontFeatures: const [FontFeature.tabularFigures()])
                          .inter(FontWeight.w700),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              )
            : _LinkButton(label: tr('Kodni qayta yuborish'), onTap: onResend, fontSize: 14),
      ),
    );
  }
}

/// Text link with a ≥44px tap area, w600 primary.
class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap, this.fontSize = 16});

  final String label;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge!
                    .copyWith(fontSize: fontSize, height: 22 / 16, color: Theme.of(context).colorScheme.primary)
                    .inter(FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 56px primary capsule; 0.45 opacity until [ready], white spinner while [loading].
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.ready, required this.loading, required this.onTap});

  final String label;
  final bool ready, loading;
  final VoidCallback? onTap;

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
          opacity: ready || loading ? 1 : 0.45,
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
