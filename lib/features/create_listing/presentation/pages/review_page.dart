import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/create_draft.dart';
import '../cubit/create_flow_cubit.dart';
import '../widgets/create_details_step.dart';
import '../widgets/create_ui.dart';
import 'create_flow_page.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/widgets/topildi_loader.dart';
import '../../../../core/widgets/t_feedback.dart';

/// Koʻrib chiqish, "readiness ring + slide to post": a ring that fills with
/// the required fields, a five-item checklist (each row opens its step),
/// and a slider that both confirms the rules and posts.
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, this.editId});

  /// Editing this own listing: it is loaded first, and "Saqlash" replaces
  /// the slide to post.
  final String? editId;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

/// One checklist row.
class _Item {
  const _Item({required this.name, required this.value, required this.done, required this.onTap});

  final String name, value;
  final bool done;
  final VoidCallback onTap;
}

class _ReviewPageState extends State<ReviewPage> with SingleTickerProviderStateMixin {
  /// The ring fills from 0 when the page opens.
  late final _fill = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  /// The listing to edit is still loading.
  late bool _loading = widget.editId != null;

  @override
  void initState() {
    super.initState();
    if (widget.editId case final id?) WidgetsBinding.instance.addPostFrameCallback((_) => _startEdit(id));
  }

  Future<void> _startEdit(String id) async {
    final f = await context.read<CreateFlowCubit>().startEdit(id);
    if (!mounted) return;
    if (f != null) {
      TFeedback.error(context, f is NetworkFailure ? tr('Internet yoʻq. Qayta urinib koʻring') : tr('Eʼlonni ochib boʻlmadi'));
      context.pop();
      return;
    }
    setState(() => _loading = false);
  }

  /// Back from an edit with unsaved changes asks first.
  Future<void> _leave(CreateFlowCubit cubit) async {
    if (cubit.state.hasChanges) {
      final ok = await TFeedback.confirm(
        context,
        title: tr('Oʻzgarishlar saqlanmasinmi?'),
        body: tr('Kiritgan oʻzgarishlaringiz yoʻqoladi.'),
        confirmLabel: tr('Saqlamasdan chiqish'),
        cancelLabel: tr('Bekor qilish'),
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    context.pop(false);
  }

  Future<void> _save(CreateFlowCubit cubit) async {
    final f = await TopildiLoader.run<Failure?>(
      context,
      task: cubit.save,
      failureOf: (f) => f,
      icon: Symbols.save_rounded,
      label: tr('Saqlanmoqda…'),
      successLabel: tr('Saqlandi'),
      errorLabel: tr('Saqlab boʻlmadi'),
    );
    if (mounted && f == null && cubit.state.status == SubmitStatus.success) context.pop(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fill.isDismissed) {
      MediaQuery.disableAnimationsOf(context) ? _fill.value = 1 : _fill.forward();
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  void _edit(String route) => context.push('$route?edit=1');

  /// No "done" state: success opens the "Eʼlon joylandi!" screen.
  Future<void> _publish(CreateFlowCubit cubit) => TopildiLoader.run<Failure?>(
    context,
    task: () async {
      await cubit.publish();
      final s = cubit.state;
      return s.status == SubmitStatus.failure ? s.failure : null;
    },
    failureOf: (f) => f,
    icon: Symbols.send_rounded,
    label: tr('Eʼlon joylanmoqda…'),
    errorLabel: tr('Joylab boʻlmadi'),
  );

  List<_Item> _items(CreateDraft d, CreateFlowCubit cubit) {
    final district = d.district;
    final landmark = d.landmark.trim();
    final hiddenOk = DraftValidator.hiddenDetail(d) == null;
    return [
      _Item(
        name: tr('Rasmlar'),
        value: d.photos.isEmpty ? tr('Rasmsiz') : tr('{n} ta rasm', {'n': d.photos.length}),
        // Optional: "Rasmsiz" is fine too.
        done: true,
        onTap: () => _edit(Routes.create),
      ),
      _Item(
        name: tr('Sarlavha va kategoriya'),
        value: [if (d.title.trim().isNotEmpty) d.title.trim(), ?d.category?.label].join(' · '),
        done: DraftValidator.title(d) == null && DraftValidator.category(d) == null,
        onTap: () => _edit(Routes.createDetails),
      ),
      _Item(
        name: tr('Joy'),
        value: district == null ? '' : [tr(district), if (landmark.isNotEmpty) landmark].join(' · '),
        done: DraftValidator.district(d) == null,
        onTap: () => _edit(Routes.createLocation),
      ),
      _Item(
        name: tr('Vaqt'),
        value: createWhenLabel(d.happenedAt(DateTime.now())),
        done: true,
        onTap: () => _edit(Routes.createLocation),
      ),
      _Item(
        name: tr('Yashirin belgi'),
        // The text itself is never shown here.
        value: cubit.state.hiddenLocked
            ? tr('Soʻrovlar kelgan · oʻzgartirib boʻlmaydi')
            : d.hiddenDetail.trim().isNotEmpty
            ? tr('Qoʻshildi · faqat siz koʻrasiz')
            : d.isFound
            ? tr('Qoʻshilmagan')
            : tr('Ixtiyoriy'),
        done: hiddenOk,
        onTap: () => editHiddenDetail(context, cubit),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);
    final cubit = context.read<CreateFlowCubit>();

    return BlocConsumer<CreateFlowCubit, CreateFlowState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) async {
        // Editing saves through _save and returns to the listing.
        if (state.isEditing) return;
        if (state.status == SubmitStatus.success) {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          if (context.mounted) context.go(Routes.createPosted);
        }
      },
      builder: (context, state) {
        if (_loading) {
          return const Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: CreateBackground()),
                Center(child: CircularProgressIndicator.adaptive()),
              ],
            ),
          );
        }
        final d = state.draft;
        final items = _items(d, cubit);
        // The ring counts the required items only.
        final required = [items[1], items[2], if (d.isFound) items[4]];
        final ready = required.where((i) => i.done).length / required.length;
        final missing = required.where((i) => !i.done).firstOrNull;
        final busy = state.status == SubmitStatus.submitting || state.status == SubmitStatus.success;
        final String? problem = missing != null
            ? tr('Avval {name}ni toʻldiring', {'name': missing.name.toLowerCase()})
            : null;
        final bottom = math.max(34.0, mq.padding.bottom);

        final editing = state.isEditing;
        return PopScope(
          canPop: !busy && !state.hasChanges,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy) _leave(cubit);
          },
          child: Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(child: CreateBackground()),
                Column(
                  children: [
                    SizedBox(height: mq.padding.top + 11),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Opacity(
                            opacity: busy ? 0.45 : 1,
                            child: CreateGlassButton(
                              icon: Symbols.arrow_back_rounded,
                              label: tr('Orqaga'),
                              onTap: busy ? () {} : (editing ? () => _leave(cubit) : () => context.pop()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                editing ? tr('Eʼlonni tahrirlash') : tr('Koʻrib chiqish'),
                                style: text.titleMedium!
                                    .copyWith(fontSize: 17, height: 22 / 17, color: cs.onSurface)
                                    .inter(FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        physics: createScrollPhysics,
                        padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 64 + 100),
                        children: [
                          _Readiness(draft: d, ready: ready, fill: _fill, capped: !editing),
                          const SizedBox(height: 32),
                          _Checklist(items: items),
                        ],
                      ),
                    ),
                  ],
                ),
                // Content fades out under the slider.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: bottom + 64 + 110,
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
                  bottom: bottom,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (problem != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              problem,
                              textAlign: TextAlign.center,
                              style: text.bodySmall!
                                  .copyWith(fontSize: 13, height: 18 / 13, color: cs.error)
                                  .inter(FontWeight.w600),
                            ),
                          ),
                        ),
                      if (editing)
                        CreatePrimaryButton(
                          label: tr('Saqlash'),
                          onTap: missing == null && state.hasChanges && !busy ? () => _save(cubit) : null,
                        )
                      else ...[
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: _Consent()),
                        const SizedBox(height: 12 - _Consent.pad),
                        _SlideToPublish(
                          enabled: missing == null,
                          status: state.status,
                          onPublish: () => _publish(cubit),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ring with the item's photo, then "HAMMASI TAYYOR" / "{n}% TAYYOR", the
/// title and the type and category chips.
class _Readiness extends StatelessWidget {
  const _Readiness({required this.draft, required this.ready, required this.fill, this.capped = true});

  final CreateDraft draft;

  /// Share of the required items filled, 0…1.
  final double ready;
  final Animation<double> fill;

  /// Stop at 99% while posting is still ahead; an edit shows the full ring.
  final bool capped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    final d = draft;
    final category = d.category;
    // Capped at 99%: publishing is the last step, so the ring never closes here.
    final shown = ready >= 1 && capped ? 0.99 : ready;
    final percent = (shown * 100).round();
    return Row(
      children: [
        SizedBox.square(
          dimension: 108,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: fill,
                builder: (context, _) => CustomPaint(
                  painter: _RingPainter(
                    value: shown * Curves.easeOutCubic.transform(fill.value),
                    track: cs.outlineVariant,
                    color: cs.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: ClipOval(
                  child: PhotoPlaceholder(
                    icon: category?.icon ?? Symbols.image_rounded,
                    tint: category?.index ?? 0,
                    path: d.photos.isEmpty ? null : d.photos.first,
                    width: 80,
                    height: 80,
                    iconSize: 38,
                    radius: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shown >= 1 ? tr('Hammasi tayyor').toUpperCase() : tr('{n}% tayyor', {'n': percent}).toUpperCase(),
                style: text.labelMedium!
                    .copyWith(fontSize: 13, height: 18 / 13, color: cs.primary)
                    .inter(FontWeight.w700),
              ),
              Text(
                d.title.trim().isEmpty ? tr('Nomsiz eʼlon') : d.title.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.headlineSmall!
                    .copyWith(fontSize: 24, height: 29 / 24, letterSpacing: -0.4, color: cs.onSurface)
                    .inter(FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Chip(
                    label: d.isFound ? tr('Topilgan') : tr('Yoʻqolgan'),
                    color: d.isFound ? tc.found : tc.lost,
                    background: d.isFound ? tc.foundContainer : tc.lostContainer,
                    dot: true,
                  ),
                  if (category != null)
                    _Chip(label: category.label, color: cs.secondary, background: CreateColors.of(context).barSoft),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.color});

  final double value;
  final Color track, color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 4.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (value <= 0) return;
    // Round caps stick out stroke/2 past each end; trim them off so a 99%
    // ring shows its gap instead of looking closed.
    final caps = value < 1 ? stroke / (rect.width / 2) : 0.0;
    canvas.drawArc(
      rect,
      -math.pi / 2 + caps / 2,
      math.max(0.0, 2 * math.pi * value - caps),
      false,
      paint
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.track != track || old.color != color;
}

/// 26-high capsule tag.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.background, this.dot = false});

  final String label;
  final Color color, background;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall!.copyWith(fontSize: 12, height: 16 / 12, color: color).inter(FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// White card of five rows; a row opens its step (or the hidden-detail sheet).
class _Checklist extends StatelessWidget {
  const _Checklist({required this.items});

  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x0F0F1420), offset: Offset(0, 10), blurRadius: 28)],
      ),
      child: Column(children: [for (final i in items) _Row(item: i)]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final i = item;
    return Semantics(
      button: true,
      label: '${i.name}, ${i.value}${i.done ? '' : ', ${tr('Qoʻshish')}'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: i.onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: i.done
                      ? BoxDecoration(color: context.tc.primaryFill, shape: BoxShape.circle)
                      : BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: CreateColors.of(context).dashed, width: 2),
                        ),
                  child: i.done ? Icon(Symbols.check_rounded, size: 18, color: cs.onPrimary) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.name,
                        style: text.titleSmall!
                            .copyWith(fontSize: 15, height: 20 / 15, color: cs.onSurface)
                            .inter(FontWeight.w600),
                      ),
                      if (i.value.isNotEmpty)
                        Text(
                          i.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall!
                              .copyWith(fontSize: 12, height: 16 / 12, color: cs.onSurfaceVariant)
                              .inter(FontWeight.w400),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (i.done)
                  Icon(Symbols.chevron_right_rounded, size: 20, color: cs.outline)
                else
                  Text(
                    tr('Qoʻshish'),
                    style: text.labelLarge!
                        .copyWith(fontSize: 14, height: 20 / 14, color: cs.primary)
                        .inter(FontWeight.w700),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Surib, maʼlumotlar toʻgʻri ekanini tasdiqlaysiz va eʼlon qoidalariga
/// rozilik bildirasiz." The link answers taps up to 22 above and below its
/// line (a 44 target).
class _Consent extends StatefulWidget {
  const _Consent();

  /// Invisible padding the larger target reaches into.
  static const pad = 12.0;

  @override
  State<_Consent> createState() => _ConsentState();
}

class _ConsentState extends State<_Consent> {
  late final _rules = TapGestureRecognizer()..onTap = _open;

  void _open() => context.push(Routes.terms);

  @override
  void dispose() {
    _rules.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = Theme.of(
      context,
    ).textTheme.bodySmall!.copyWith(fontSize: 12, height: 17 / 12, color: cs.onSurfaceVariant).inter(FontWeight.w400);
    final parts = [
      tr('Surib, maʼlumotlar toʻgʻri ekanini tasdiqlaysiz va '),
      tr('eʼlon qoidalari'),
      tr('ga rozilik bildirasiz.'),
    ];
    final span = TextSpan(
      style: base,
      children: [
        TextSpan(text: parts[0]),
        TextSpan(
          text: parts[1],
          style: base.copyWith(color: cs.primary).inter(FontWeight.w600),
          recognizer: _rules,
        ),
        TextSpan(text: parts[2]),
      ],
    );
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) {
          final at = details.localPosition - const Offset(0, _Consent.pad);
          final painter = TextPainter(
            text: span,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout(maxWidth: box.maxWidth);
          final start = parts[0].length;
          final hit = painter
              .getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: start + parts[1].length))
              .map((b) => b.toRect())
              .any((r) => Rect.fromLTRB(r.left - 4, r.center.dy - 22, r.right + 4, r.center.dy + 22).contains(at));
          painter.dispose();
          if (hit) _open();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _Consent.pad),
          child: Text.rich(span, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// "Eʼlon qilish uchun suring": drag the white knob past 85% to post; let go
/// earlier and it springs back. A tap does nothing, except for screen
/// reader users, who get a plain "Eʼlon qilish" button.
class _SlideToPublish extends StatefulWidget {
  const _SlideToPublish({required this.enabled, required this.status, required this.onPublish});

  final bool enabled;
  final SubmitStatus status;
  final VoidCallback onPublish;

  @override
  State<_SlideToPublish> createState() => _SlideToPublishState();
}

class _SlideToPublishState extends State<_SlideToPublish> with SingleTickerProviderStateMixin {
  static const _height = 64.0;
  static const _knob = 52.0;
  static const _inset = 6.0;
  static const _threshold = 0.85;

  /// Knob offset from the left, in pixels.
  late final _dx = AnimationController.unbounded(vsync: this);
  double _max = 0;
  bool _dragging = false;
  bool _hinted = false;
  Timer? _hintTimer;
  int _nudges = 0;

  bool get _busy => widget.status == SubmitStatus.submitting || widget.status == SubmitStatus.success;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    if (!_hinted && !mq.disableAnimations && !mq.accessibleNavigation) {
      _hinted = true;
      _scheduleHint(const Duration(milliseconds: 1500));
    }
  }

  @override
  void didUpdateWidget(_SlideToPublish old) {
    super.didUpdateWidget(old);
    // A failed post: the knob comes back for another try.
    if (old.status != widget.status && widget.status == SubmitStatus.failure) _springBack();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _dx.dispose();
    super.dispose();
  }

  /// 1.5s after opening, the knob nudges 14 to the right and back, three times.
  void _scheduleHint(Duration after) => _hintTimer = Timer(after, _nudge);

  Future<void> _nudge() async {
    if (!mounted || _dragging || _busy || !widget.enabled || _dx.value != 0) return;
    await _dx.animateTo(14, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    if (!mounted || _dragging) return;
    await _dx.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeIn);
    if (mounted && ++_nudges < 3) _scheduleHint(const Duration(milliseconds: 1600));
  }

  void _springBack() => _dx.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutBack);

  void _end() {
    _dragging = false;
    if (_max > 0 && _dx.value >= _threshold * _max) {
      _dx.animateTo(_max, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
      HapticFeedback.mediumImpact();
      widget.onPublish();
    } else {
      _springBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final screenReader = MediaQuery.accessibleNavigationOf(context);
    final enabled = widget.enabled && !_busy;
    final status = widget.status;
    final label = switch (status) {
      SubmitStatus.submitting => tr('Eʼlon qilinmoqda…'),
      SubmitStatus.success => tr('Eʼlon qilindi!'),
      _ when screenReader => tr('Eʼlon qilish'),
      _ => tr('Eʼlon qilish uchun suring'),
    };
    final labelStyle = text.labelLarge!
        .copyWith(fontSize: 17, height: 22 / 17, color: cs.onPrimary)
        .inter(FontWeight.w700);

    return Semantics(
      button: true,
      enabled: enabled,
      label: tr('Eʼlon qilish'),
      onTap: enabled ? widget.onPublish : null,
      excludeSemantics: true,
      child: Opacity(
        opacity: widget.enabled || _busy ? 1 : 0.45,
        child: LayoutBuilder(
          builder: (context, box) {
            _max = box.maxWidth - 2 * _inset - _knob;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Screen readers (and switch access) post with one activation.
              onTap: screenReader && enabled ? widget.onPublish : null,
              onHorizontalDragStart: enabled && !screenReader
                  ? (_) {
                      _dragging = true;
                      _dx.stop();
                    }
                  : null,
              onHorizontalDragUpdate: enabled && !screenReader
                  ? (d) => _dx.value = (_dx.value + d.delta.dx).clamp(0.0, _max)
                  : null,
              onHorizontalDragEnd: enabled && !screenReader ? (_) => _end() : null,
              onHorizontalDragCancel: enabled && !screenReader ? _end : null,
              child: Container(
                height: _height,
                decoration: BoxDecoration(
                  color: context.tc.primaryFill,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryGlow(0.3),
                      offset: const Offset(0, 12),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _dx,
                  builder: (context, _) {
                    final progress = _max <= 0 ? 0.0 : (_dx.value / _max).clamp(0.0, 1.0);
                    final idle = !_busy;
                    return Stack(
                      children: [
                        Positioned.fill(
                          left: screenReader ? 20 : _inset + _knob,
                          right: 20,
                          child: Opacity(
                            opacity: idle ? 1 - progress : 1,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(label, maxLines: 1, style: labelStyle),
                                    if (idle && !screenReader) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        Symbols.keyboard_double_arrow_right_rounded,
                                        size: 20,
                                        color: cs.onPrimary.withValues(alpha: 0.7),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!screenReader)
                          Positioned(
                            left: _inset + _dx.value,
                            top: _inset,
                            child: Container(
                              key: const ValueKey('publish-knob'),
                              width: _knob,
                              height: _knob,
                              decoration: BoxDecoration(color: cs.onPrimary, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: switch (status) {
                                SubmitStatus.submitting => CupertinoActivityIndicator(color: cs.primary),
                                SubmitStatus.success => Icon(Symbols.check_rounded, size: 26, color: cs.primary),
                                _ => Icon(Symbols.send_rounded, size: 24, fill: 1, color: cs.primary),
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
