import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/glass_empty_icon.dart';
import '../../../../core/widgets/glass_sheet.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/t_sheet_button.dart';
import '../../../../core/widgets/topildi_loader.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/report.dart';
import '../../domain/usecases/check_reported.dart';
import '../../domain/usecases/watch_report.dart';
import '../../domain/usecases/submit_report.dart';

/// Opens "Shikoyat qilish" for [target]: the form, or — when this person has
/// reported it before — the same sheet showing where that one has got to.
/// Sending keeps the sheet open and swaps its content for the thank-you.
Future<void> showReportSheet(BuildContext context, {required ReportTarget target}) async {
  final result = await TopildiLoader.run<Either<Failure, MyReport?>>(
    context,
    task: () => getIt<CheckReported>()((type: target.type, targetId: target.id)),
    icon: Symbols.flag_rounded,
    label: tr('Tekshirilmoqda…'),
    errorLabel: tr('Shikoyat qilib boʻlmadi'),
    failureOf: (r) => r.getLeft().toNullable(),
  );
  if (result == null || !context.mounted) return;
  final mine = result.getOrElse((_) => null);
  await showGlassSheet<void>(
    context,
    label: tr('Shikoyat qilish'),
    builder: (_) => _ReportSheet(target: target, mine: mine),
  );
}

/// What the sheet is showing: an earlier shikoyat's progress, the form, or
/// the thank-you. One widget, so each step fades into the next inside the
/// same sheet.
enum _Phase { status, form, sent }

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.target, this.mine});

  final ReportTarget target;

  /// This person's earlier shikoyat on the target, if there is one.
  final MyReport? mine;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _comment = TextEditingController();
  final _commentFocus = FocusNode();
  late _Phase _phase = widget.mine == null ? _Phase.form : _Phase.status;

  /// The earlier shikoyat, live: while the steps are on screen the
  /// moderator's decision lands on them by itself.
  late final StreamEither<MyReport?>? _live = widget.mine == null
      ? null
      : getIt<WatchReport>()((type: widget.target.type, targetId: widget.target.id));

  @override
  void initState() {
    super.initState();
    _comment.addListener(() => setState(() {}));
    _commentFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comment.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  /// The note carries everything the moderator needs, so no reason is
  /// chosen: Firestore gets `other` for the field it requires.
  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final result = await TopildiLoader.run<Either<Failure, void>>(
      context,
      task: () => getIt<SubmitReport>()(
        SubmitReportParams(
          target: widget.target,
          reason: ReportReason.other,
          comment: _comment.text.trim(),
        ),
      ),
      icon: Symbols.flag_rounded,
      label: tr('Yuborilmoqda…'),
      // The sheet shows the result itself, so the capsule just goes.
      successLabel: null,
      errorLabel: tr('Shikoyat qilib boʻlmadi'),
      failureOf: (r) => r.getLeft().toNullable(),
    );
    if (result == null || !mounted || result.isLeft()) return;
    HapticFeedback.lightImpact();
    setState(() => _phase = _Phase.sent);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_phase) {
          _Phase.status => StreamBuilder<Either<Failure, MyReport?>>(
            stream: _live,
            builder: (context, snapshot) {
              final report = snapshot.data?.toNullable() ?? widget.mine!;
              return _AlreadySent(
                target: widget.target,
                report: report,
                // A closed one is theirs to raise again, from the same sheet.
                onAgain: report.isOpen ? null : () => setState(() => _phase = _Phase.form),
              );
            },
          ),
          _Phase.form => _form(context),
          _Phase.sent => const _Sent(),
        },
      ),
    );
  }

  Widget _form(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant;
    final count = _comment.text.characters.length;
    final enough = _comment.text.trim().characters.length >= minReportComment;
    // With the keyboard up the sheet rides above it, so the room it leaves
    // goes to the field; the anonymity line steps aside.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Header(),
          const SizedBox(height: 14),
          _TargetCard(target: widget.target),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(child: _Label(tr('IZOH'))),
                Text(
                  '$count / $maxReportComment',
                  style: TextStyle(fontSize: 13, color: muted).inter(FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: keyboard ? 150 : 190),
              child: _CommentField(controller: _comment, focusNode: _commentFocus),
            ),
          ),
          if (!keyboard) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.lock_rounded, size: 14, fill: 1, color: cs.outline),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    tr('Shikoyat anonim · 24 soat ichida koʻrib chiqiladi'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, height: 16 / 12, color: cs.outline).inter(FontWeight.w400),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TSheetButton(label: tr('Yuborish'), onTap: enough ? _send : null),
        ],
      ),
    );
  }
}

/// Yopish · "Shikoyat qilish" — the Filtrlar sheet's panel, without a
/// trailing action.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final g = context.glass;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                tr('Shikoyat qilish'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontSize: 17, height: 22 / 17).inter(FontWeight.w600),
              ),
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: tr('Yopish'),
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox.square(
                        dimension: 44,
                        child: GlassSurface(
                          color: g.control,
                          child: Icon(Symbols.close_rounded, size: 22, color: cs.onSurface),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Keeps the title centred against the close button.
                  const SizedBox(width: 44),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SH5: the sheet's content after a shikoyat went through. No offer to
/// block — that is a decision of its own, from the menu.
class _Sent extends StatelessWidget {
  const _Sent();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: GlassEmptyIcon(icon: Symbols.verified_user_rounded, badge: GlassIconBadge.none)),
          const SizedBox(height: 8),
          Text(
            tr('Shikoyatingiz yuborildi'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, color: cs.onSurface).inter(FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Rahmat! Moderator 24 soat ichida koʻrib chiqadi. Kim shikoyat qilgani hech kimga koʻrsatilmaydi.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 21 / 15, color: cs.onSurfaceVariant).inter(FontWeight.w400),
          ),
          const SizedBox(height: 22),
          TSheetButton(label: tr('Tayyor'), onTap: () => Navigator.of(context).maybePop()),
        ],
      ),
    );
  }
}

/// SH6: this person has already reported the same target, so the sheet
/// shows where that shikoyat has got to instead of the form. While it is
/// open there is no button — the X or a pull down closes it; once the
/// moderator has closed it, [onAgain] opens the form again.
class _AlreadySent extends StatelessWidget {
  const _AlreadySent({required this.target, required this.report, this.onAgain});

  final ReportTarget target;
  final MyReport report;
  final VoidCallback? onAgain;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final at = report.createdAt;
    final open = report.isOpen;
    final dismissed = report.status == ReportStatus.dismissed;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          const SizedBox(height: 14),
          _TargetCard(target: target),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('Shikoyatingiz allaqachon yuborilgan'),
                  style: TextStyle(fontSize: 17, color: cs.onSurface).inter(FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _Step(
                  marker: _StepMarker.done,
                  lineBelow: cs.primary,
                  title: tr('Yuborildi'),
                  subtitle: at == null ? null : TDate.relative(at, withTimeForOld: true),
                ),
                _Step(
                  marker: open ? _StepMarker.current : _StepMarker.done,
                  lineBelow: open || dismissed ? cs.outlineVariant : cs.primary,
                  title: open ? tr('Moderator koʻrib chiqmoqda') : tr('Koʻrib chiqildi'),
                  subtitle: open ? tr('Odatda 24 soat ichida') : null,
                ),
                // The last step keeps its name in both states; only the
                // marker and the line under it say how it ended.
                _Step(
                  marker: switch (report.status) {
                    ReportStatus.open => _StepMarker.waiting,
                    ReportStatus.resolved => _StepMarker.result,
                    ReportStatus.dismissed => _StepMarker.neutral,
                  },
                  title: tr('Natija'),
                  subtitle: switch (report.status) {
                    ReportStatus.open => tr('Moderator qarori shu yerda koʻrinadi'),
                    ReportStatus.resolved => tr('Chora koʻrildi. Rahmat!'),
                    ReportStatus.dismissed => tr('Qoidabuzarlik topilmadi'),
                  },
                  dim: open || dismissed,
                ),
              ],
            ),
          ),
          if (onAgain != null) ...[
            const SizedBox(height: 16),
            TSheetButton(label: tr('Yana shikoyat qilish'), onTap: onAgain),
          ],
        ],
      ),
    );
  }
}

enum _StepMarker { done, current, waiting, result, neutral }

/// One step of the shikoyat's progress: the marker, the line down to the
/// next one, and the two lines of text beside them.
class _Step extends StatelessWidget {
  const _Step({
    required this.marker,
    required this.title,
    this.subtitle,
    this.lineBelow,
    this.dim = false,
  });

  final _StepMarker marker;
  final String title;
  final String? subtitle;

  /// Colour of the 2dp rail down to the next step; null on the last one.
  final Color? lineBelow;

  /// A step still to come is greyed out.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sub = subtitle;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                _Marker(marker),
                if (lineBelow != null)
                  Expanded(child: Center(child: Container(width: 2, color: lineBelow))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: lineBelow == null ? 14 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      height: 20 / 15,
                      color: dim ? cs.outline : cs.onSurface,
                    ).inter(dim ? FontWeight.w600 : FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  // Kept even when there is nothing to say, so every step is
                  // the same height and the markers stay evenly spaced.
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 16),
                    child: sub == null
                        ? const SizedBox.shrink()
                        : Text(
                            sub,
                            style: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              color: dim ? cs.outline.withValues(alpha: 0.75) : cs.onSurfaceVariant,
                            ).inter(FontWeight.w400),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker(this.kind);

  final _StepMarker kind;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (kind) {
      _StepMarker.done => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        child: Icon(Symbols.check_rounded, size: 18, color: cs.onPrimary),
      ),
      // The ring around it is the halo of the design, drawn as a spread
      // shadow so it costs no layout.
      _StepMarker.current => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.12), spreadRadius: 5)],
        ),
        child: SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: cs.primary,
            // "Kamroq harakat": the same ring, standing still.
            value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
          ),
        ),
      ),
      // Something was done about it: solid, like the steps above, with a
      // shield and tick instead of a third bare tick.
      _StepMarker.result => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        child: Icon(Symbols.verified_user_rounded, size: 17, fill: 1, color: cs.onPrimary),
      ),
      // Looked at, nothing found: the chain ends quietly, in grey.
      _StepMarker.neutral => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: cs.surfaceContainerHigh, shape: BoxShape.circle),
        child: Icon(Symbols.remove_rounded, size: 18, color: cs.onSurfaceVariant),
      ),
      _StepMarker.waiting => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cs.outlineVariant, width: 2),
        ),
        child: Icon(Symbols.notifications_rounded, size: 16, color: cs.outline.withValues(alpha: 0.75)),
      ),
    };
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      letterSpacing: 0.6,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ).inter(FontWeight.w700),
  );
}

/// What is being reported: a thumbnail, the title, and "Eʼlon · {name}".
class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.target});

  final ReportTarget target;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final kind = target.type == ReportTargetType.listing ? tr('Eʼlon') : tr('Chat');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          PhotoPlaceholder(
            icon: target.category.icon,
            tint: target.tint,
            path: target.photoUrl,
            width: 44,
            height: 44,
            iconSize: 24,
            radius: 14,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: cs.onSurface).inter(FontWeight.w700),
                ),
                Text(
                  '$kind · ${target.personName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant).inter(FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The only thing the sheet asks for, so it opens focused and fills the
/// space the sheet can spare.
class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: color, width: width),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: focusNode.hasFocus
            ? [BoxShadow(color: cs.primary.withValues(alpha: 0.10), blurRadius: 22, offset: const Offset(0, 8))]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        expands: true,
        minLines: null,
        maxLines: null,
        maxLength: maxReportComment,
        textAlignVertical: TextAlignVertical.top,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(fontSize: 16, height: 22 / 16, color: cs.onSurface).inter(FontWeight.w400),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: cs.surfaceContainerLowest,
          hintText: tr('Nima boʻldi? Batafsil yozing — moderatorga yordam beradi'),
          hintStyle: TextStyle(fontSize: 16, height: 22 / 16, color: cs.outline).inter(FontWeight.w400),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: border(cs.outlineVariant, 1),
          enabledBorder: border(cs.outlineVariant, 1),
          focusedBorder: border(cs.primary, 2),
        ),
      ),
    );
  }
}
