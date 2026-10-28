import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../error/failure.dart';
import '../l10n/tr.dart';
import '../theme/t_text.dart';

/// Ring colour of the running capsule: primary, or error for deletions.
enum LoaderTone { normal, danger }

/// One white glass capsule for every long action (delete, save, sign out,
/// send…). It drops from under the Dynamic Island / status bar over a dim
/// layer that blocks touches and Android back, spins while [run]'s task
/// works, then shows "done" for 1.2 s, or an error with "Qayta".
///
/// Lives in the root overlay, so it survives navigation. One at a time:
/// a second [run] waits for the first.
abstract final class TopildiLoader {
  static _LoaderController? _active;

  /// Completes when the running capsule is gone.
  static Completer<void>? _slot;

  /// Runs [task] under the capsule and returns its result, or null when
  /// the user closed the capsule after a failure.
  ///
  /// [failureOf] tells a failed result apart (cubits return a [Failure]
  /// instead of throwing); a thrown error is a failure too. [successLabel]
  /// null closes without the "done" state, for flows that open their own
  /// success screen. The capsule never shows for tasks under 300 ms, and
  /// once shown stays at least 600 ms.
  static Future<T?> run<T>(
    BuildContext context, {
    required Future<T> Function() task,
    required IconData icon,
    required String label,
    String? subtitle,
    LoaderTone tone = LoaderTone.normal,
    String? successLabel,
    required String errorLabel,
    Failure? Function(T result)? failureOf,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    // One at a time. A capsule whose overlay is gone (app rebuilt, test
    // torn down) can't finish: don't wait for it.
    for (var s = _slot; s != null && !s.isCompleted; s = _slot) {
      if (_active case final a? when !a.overlay.mounted) break;
      await s.future;
    }
    final slot = _slot = Completer<void>();
    final c = _LoaderController(overlay: overlay, icon: icon, label: label, subtitle: subtitle, tone: tone);
    _active = c;
    try {
      return await c.drive(task: task, successLabel: successLabel, errorLabel: errorLabel, failureOf: failureOf);
    } finally {
      if (identical(_active, c)) _active = null;
      slot.complete();
    }
  }

  /// Updates the running capsule's text, e.g. "Rasmlar yuklanmoqda · 2/3".
  static void update({String? label, String? subtitle}) => _active?.update(label: label, subtitle: subtitle);
}

enum _Phase { loading, done, error }

class _LoaderController {
  _LoaderController({
    required this.overlay,
    required IconData icon,
    required String label,
    required String? subtitle,
    required this.tone,
  }) : state = ValueNotifier(_View(_Phase.loading, icon, label, subtitle));

  final OverlayState overlay;
  final LoaderTone tone;
  final ValueNotifier<_View> state;
  final _visible = ValueNotifier(false);
  OverlayEntry? _entry;
  DateTime? _shownAt;

  /// Completes with true for "Qayta", false when the dim layer is tapped.
  Completer<bool>? _decision;

  void update({String? label, String? subtitle}) {
    final v = state.value;
    if (v.phase != _Phase.loading) return;
    state.value = v.copyWith(label: label ?? v.label, subtitle: subtitle ?? v.subtitle);
  }

  void _show() {
    if (_entry != null) return;
    _entry = OverlayEntry(
      // Root overlay sits outside any Scaffold: give the text a Material.
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: _LoaderLayer(
          state: state,
          visible: _visible,
          tone: tone,
          onRetry: () => _decision?.complete(true),
          onDismiss: () {
            if (state.value.phase == _Phase.error) _decision?.complete(false);
          },
        ),
      ),
    );
    overlay.insert(_entry!);
    _shownAt = DateTime.now();
    // A frame in the hidden pose first, so the drop animates.
    WidgetsBinding.instance.addPostFrameCallback((_) => _visible.value = true);
  }

  Future<void> _hide() async {
    if (_entry == null) return;
    _visible.value = false;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _entry?.remove();
    _entry = null;
    state.dispose();
    _visible.dispose();
  }

  Future<T?> drive<T>({
    required Future<T> Function() task,
    required String? successLabel,
    required String errorLabel,
    required Failure? Function(T result)? failureOf,
  }) async {
    final start = state.value;
    while (true) {
      // Quick tasks never show the capsule.
      final appear = Timer(const Duration(milliseconds: 300), _show);
      Object? failure;
      T? result;
      try {
        final r = await task();
        result = r;
        failure = failureOf?.call(r);
      } catch (e) {
        failure = e;
      }
      appear.cancel();

      if (failure == null) {
        if (_entry == null) return result;
        final shown = DateTime.now().difference(_shownAt!);
        if (shown < const Duration(milliseconds: 600)) {
          await Future<void>.delayed(const Duration(milliseconds: 600) - shown);
        }
        if (successLabel != null) {
          state.value = _View(_Phase.done, Symbols.check_rounded, successLabel, null);
          HapticFeedback.lightImpact();
          await Future<void>.delayed(const Duration(milliseconds: 1200));
        }
        await _hide();
        return result;
      }

      _show();
      state.value = _View(_Phase.error, start.icon, errorLabel, _reason(failure));
      HapticFeedback.heavyImpact();
      _decision = Completer();
      final retry = await _decision!.future;
      _decision = null;
      if (!retry) {
        await _hide();
        return null;
      }
      state.value = start;
    }
  }

  static String? _reason(Object failure) => switch (failure) {
    NetworkFailure() => tr('Internetni tekshiring'),
    Failure(:final message?) when message.isNotEmpty => message,
    _ => null,
  };
}

class _View {
  const _View(this.phase, this.icon, this.label, this.subtitle);

  final _Phase phase;
  final IconData icon;
  final String label;
  final String? subtitle;

  _View copyWith({String? label, String? subtitle}) => _View(phase, icon, label ?? this.label, subtitle);
}

/// Dim layer plus the capsule. Blocks touches and Android back while the
/// task runs; in the error state a tap on the layer closes it.
class _LoaderLayer extends StatelessWidget {
  const _LoaderLayer({
    required this.state,
    required this.visible,
    required this.tone,
    required this.onRetry,
    required this.onDismiss,
  });

  final ValueListenable<_View> state;
  final ValueListenable<bool> visible;
  final LoaderTone tone;
  final VoidCallback onRetry, onDismiss;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final width = math.min(MediaQuery.sizeOf(context).width - 32, 340.0);
    return BackButtonListener(
      // Swallow Android back for as long as the capsule is up.
      onBackButtonPressed: () async {
        if (state.value.phase == _Phase.error) onDismiss();
        return true;
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (context, on, _) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDismiss,
                child: AnimatedOpacity(
                  opacity: on ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: ColoredBox(color: dark ? const Color(0x730F1420) : const Color(0x73F4F6FA)),
                ),
              ),
            ),
            // Drops from the island: top ≈14, scale (0.4, 0.6), transparent.
            TweenAnimationBuilder<double>(
              tween: Tween(end: on ? 1 : 0),
              duration: Duration(milliseconds: reduce ? 200 : 450),
              curve: reduce || !on ? Curves.easeOut : const Cubic(0.2, 1.2, 0.3, 1),
              builder: (context, t, child) {
                final y = 14 + ((top + 8) - 14) * (reduce ? 1 : t);
                return Positioned(
                  top: y,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform(
                        alignment: Alignment.topCenter,
                        transform: reduce
                            ? Matrix4.identity()
                            : Matrix4.diagonal3Values(0.4 + 0.6 * t, 0.6 + 0.4 * t, 1),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
              child: SizedBox(
                width: width,
                child: ValueListenableBuilder<_View>(
                  valueListenable: state,
                  builder: (context, v, _) => _Capsule(view: v, tone: tone, onRetry: onRetry),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Capsule extends StatelessWidget {
  const _Capsule({required this.view, required this.tone, required this.onRetry});

  final _View view;
  final LoaderTone tone;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = dark ? const Color(0xFF8DB0FF) : const Color(0xFF2B5FD9);
    final error = dark ? const Color(0xFFFF8A80) : const Color(0xFFC2362B);
    final color = switch (view.phase) {
      _Phase.done => primary,
      _Phase.error => error,
      _Phase.loading => tone == LoaderTone.danger ? error : primary,
    };
    final title = dark ? const Color(0xFFE6EBF5) : const Color(0xFF172033);
    final muted = dark ? const Color(0xFF9AA6BB) : const Color(0xFF556070);
    final subtitle = view.subtitle;
    return Semantics(
      liveRegion: true,
      label: [view.label.replaceAll('…', ''), ?subtitle].join('. '),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 60,
            padding: const EdgeInsets.only(left: 12, right: 14),
            decoration: BoxDecoration(
              color: dark ? const Color(0xDB182031) : const Color(0xDBFFFFFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: dark ? const Color(0x1FFFFFFF) : const Color(0x99FFFFFF)),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: _Ring(phase: view.phase, icon: view.icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          view.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, height: 20 / 15, color: title).inter(FontWeight.w700),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, height: 16 / 12, color: muted).inter(FontWeight.w400),
                          ),
                      ],
                    ),
                  ),
                ),
                if (view.phase == _Phase.error)
                  Semantics(
                    button: true,
                    label: tr('Qayta'),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onRetry,
                      child: SizedBox(
                        width: 56,
                        height: 44,
                        child: Center(
                          child: Text(tr('Qayta'), style: TextStyle(fontSize: 13, color: error).inter(FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).withShadow(dark);
  }
}

extension on Widget {
  /// Soft drop shadow outside the clipped glass.
  Widget withShadow(bool dark) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      boxShadow: [
        BoxShadow(
          color: dark ? const Color(0x73000000) : const Color(0x290F1420),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: this,
  );
}

/// 36×36: a faint track, a spinning 28% arc (loading) or a full circle
/// (done / error), and the action icon in the middle.
class _Ring extends StatefulWidget {
  const _Ring({required this.phase, required this.icon, required this.color});

  final _Phase phase;
  final IconData icon;
  final Color color;

  @override
  State<_Ring> createState() => _RingState();
}

class _RingState extends State<_Ring> with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Ring old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final spin = widget.phase == _Phase.loading && !MediaQuery.disableAnimationsOf(context);
    if (spin && !_spin.isAnimating) _spin.repeat();
    if (!spin) _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.phase == _Phase.loading;
    final icon = switch (widget.phase) {
      _Phase.loading => widget.icon,
      _Phase.done => Symbols.check_rounded,
      _Phase.error => Symbols.priority_high_rounded,
    };
    return SizedBox.square(
      dimension: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: loading ? 0.28 : 1),
            duration: const Duration(milliseconds: 200),
            builder: (context, sweep, _) => AnimatedBuilder(
              animation: _spin,
              builder: (context, _) => CustomPaint(
                size: const Size.square(36),
                painter: _RingPainter(color: widget.color, sweep: sweep, turn: loading ? _spin.value : 0),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, key: ValueKey(icon), size: 18, weight: loading ? 400 : 600, color: widget.color),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.sweep, required this.turn});

  final Color color;
  final double sweep, turn;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: 14);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = color.withValues(alpha: 0.15));
    canvas.drawArc(
      rect,
      -math.pi / 2 + 2 * math.pi * turn,
      2 * math.pi * sweep,
      false,
      paint
        ..color = color
        ..strokeCap = sweep < 1 ? StrokeCap.round : StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color || old.sweep != sweep || old.turn != turn;
}
