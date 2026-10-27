import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../domain/entities/create_draft.dart';
import '../cubit/create_flow_cubit.dart';
import '../widgets/create_details_step.dart';
import '../widgets/create_location_step.dart';
import '../widgets/create_preview_card.dart';
import '../widgets/create_type_step.dart';
import '../widgets/create_ui.dart';

/// The three create steps in one screen, "live card" style: the top bar
/// (progress) and the preview card stay put while the forms slide in a
/// [PageView] under them; the button floats at the bottom. Steps are moved
/// by the button (each validates first) and by back, never by a swipe, so
/// an invalid step cannot be skipped.
///
/// From Review, "Oʻzgartirish" opens a single [initialStep] with [editing]:
/// the button saves and returns.
class CreateFlowPage extends StatefulWidget {
  const CreateFlowPage({super.key, this.initialStep = 0, this.editing = false});

  final int initialStep;
  final bool editing;

  @override
  State<CreateFlowPage> createState() => _CreateFlowPageState();
}

class _CreateFlowPageState extends State<CreateFlowPage> {
  static const _count = 3;
  static const _slide = Duration(milliseconds: 320);

  /// From the bottom of the top bar to the form: label + tilted card.
  /// Step 2's form starts 8 higher.
  static double _formTop(int step) => step == 1 ? 282 : 290;

  late int _step = widget.initialStep;
  late final _pages = PageController(initialPage: widget.initialStep);

  /// One per step: the card rides on the shown step's scroll.
  final _scrolls = List.generate(_count, (_) => ScrollController());

  @override
  void dispose() {
    _pages.dispose();
    for (final s in _scrolls) {
      s.dispose();
    }
    super.dispose();
  }

  Widget _body(int step) {
    final controller = _scrolls[step];
    final top = _formTop(step);
    return switch (step) {
      0 => CreateTypeStep(controller: controller, top: top),
      1 => CreateDetailsStep(controller: controller, top: top),
      _ => CreateLocationStep(controller: controller, top: top),
    };
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    // A step opens without red; errors come back only after "Keyingi".
    context.read<CreateFlowCubit>().hideErrors();
    setState(() => _step = step);
    _pages.animateToPage(step, duration: _slide, curve: Curves.easeOutCubic);
  }

  Future<void> _back() async {
    if (_step > 0 && !widget.editing) return _go(_step - 1);
    final draft = context.read<CreateFlowCubit>().state.draft;
    if (!widget.editing && !draft.isEmpty && !await confirmLeaveCreate(context)) return;
    if (mounted) context.pop();
  }

  /// Validates the current step, then moves on (or saves, when editing).
  void _next() {
    FocusScope.of(context).unfocus();
    final cubit = context.read<CreateFlowCubit>();
    final ok = switch (_step) {
      1 => cubit.submitDetails(),
      2 => cubit.submitLocation(),
      _ => true,
    };
    if (!ok) {
      HapticFeedback.lightImpact();
      return;
    }
    if (widget.editing) {
      context.pop();
    } else if (_step < _count - 1) {
      _go(_step + 1);
    } else {
      context.push(Routes.createReview);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = CreateColors.of(context);
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom > 0;
    final last = _step == _count - 1;
    final (label, icon) = widget.editing
        ? (tr('Saqlash'), null)
        : last
        ? (tr('Koʻrib chiqish'), CreateIcons.review)
        : (tr('Keyingi'), CreateIcons.next);
    final draft = context.select((CreateFlowCubit c) => c.state.draft);
    final scroll = _scrolls[_step];
    final buttonBottom = keyboard ? mq.viewInsets.bottom + 12 : math.max(34.0, mq.padding.bottom);

    return PopScope(
      // Back (gesture or button) returns to the previous step first, and
      // asks before throwing away what was entered.
      canPop: widget.editing || (_step == 0 && draft.isEmpty),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            const Positioned.fill(child: CreateBackground()),
            // Wash behind the card, 250 tall from just under the top bar.
            Positioned(
              left: 0,
              right: 0,
              top: mq.padding.top + 65,
              height: 250,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [c.glow, c.glow.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(height: mq.padding.top + 11),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TopBar(
                    title: _step == 2 ? tr('Qayerda va qachon?') : tr('Yangi eʼlon'),
                    step: _step + 1,
                    leadingIcon: _step == 0 && !widget.editing ? Symbols.close_rounded : Symbols.arrow_back_rounded,
                    leadingLabel: _step == 0 && !widget.editing ? tr('Yopish') : tr('Orqaga'),
                    onLeading: _back,
                  ),
                ),
                Expanded(
                  // Card and form scroll as one (with the iOS bounce); both
                  // fade out at the top bar instead of being cut, and never
                  // pass over it.
                  child: ClipRect(
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (r) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: const [Color(0x00000000), Color(0xFF000000)],
                        stops: [0, createFormTopPadding / r.height],
                      ).createShader(r),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: widget.editing
                                ? _body(_step)
                                : PageView(
                                    controller: _pages,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: [for (var i = 0; i < _count; i++) _KeepAlive(child: _body(i))],
                                  ),
                          ),
                          // The card stays put while the steps slide, and moves
                          // with the shown step's scroll (down too, when pulled).
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: AnimatedBuilder(
                              animation: scroll,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, scroll.hasClients ? -scroll.offset : 0),
                                child: child,
                              ),
                              child: _CardArea(draft: draft, showWhen: _step == 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // The form fades out under the button.
            Positioned(
              left: 0,
              right: 0,
              bottom: keyboard ? mq.viewInsets.bottom : 0,
              height: 120,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [cs.surface.withValues(alpha: 0), cs.surface],
                      stops: const [0, 0.35],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: buttonBottom,
              child: CreatePrimaryButton(label: label, icon: icon, onTap: _next),
            ),
          ],
        ),
      ),
    );
  }
}

/// Band under the top bar where scrolled content fades out.
const createFormTopPadding = 16.0;

/// iOS scrolling with the bounce, even when the step fits the screen.
const createScrollPhysics = AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());

/// Bottom padding a step's scroll view needs to clear the floating button.
double createFormBottomPadding(BuildContext context) {
  final mq = MediaQuery.of(context);
  final keyboard = mq.viewInsets.bottom > 0;
  return (keyboard ? mq.viewInsets.bottom + 12 : math.max(34.0, mq.padding.bottom)) + 56 + 24;
}

/// Glass close/back, the title with "n/3" and three progress segments.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.step,
    required this.leadingIcon,
    required this.leadingLabel,
    required this.onLeading,
  });

  final String title, leadingLabel;
  final int step;
  final IconData leadingIcon;
  final VoidCallback onLeading;

  static const _names = ['rasm va tur', 'maʼlumotlar', 'joy va sana'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final rest = CreateColors.of(context).progressRest;
    return Row(
      children: [
        CreateGlassButton(icon: leadingIcon, label: leadingLabel, onTap: onLeading),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall!
                            .copyWith(fontSize: 15, height: 20 / 15, color: cs.onSurface)
                            .inter(FontWeight.w700),
                      ),
                    ),
                  ),
                  Text(
                    '$step/3',
                    style: text.titleSmall!
                        .copyWith(fontSize: 15, height: 20 / 15, color: cs.onSurfaceVariant)
                        .inter(FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Semantics(
                label: tr('{step}-qadam: {name}', {'step': step, 'name': tr(_names[step - 1])}),
                value: '$step / 3',
                child: Row(
                  children: [
                    for (var i = 1; i <= 3; i++) ...[
                      if (i > 1) const SizedBox(width: 4),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= step ? cs.primary : rest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "EʼLONINGIZ SHUNDAY KOʻRINADI" and the card, 70 in from each side.
class _CardArea extends StatelessWidget {
  const _CardArea({required this.draft, required this.showWhen});

  final CreateDraft draft;
  final bool showWhen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ExcludeSemantics(
            child: Text(
              tr('Eʼloningiz shunday koʻrinadi').toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall!
                  .copyWith(fontSize: 11, height: 14 / 11, letterSpacing: 1.2, color: cs.onSurfaceVariant)
                  .inter(FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 70),
          child: CreatePreviewCard(draft: draft, showWhen: showWhen),
        ),
      ],
    );
  }
}

/// Keeps a step's state (text fields, scroll) while another step is shown.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
