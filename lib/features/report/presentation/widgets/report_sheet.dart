import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/widgets/glass_empty_icon.dart';
import '../../../../core/widgets/glass_sheet.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../../core/widgets/t_sheet_button.dart';
import '../../../../core/widgets/topildi_loader.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/report.dart';
import '../../domain/usecases/check_reported.dart';
import '../../domain/usecases/submit_report.dart';

/// Opens "Shikoyat qilish" for [target]: the form, or — when this person has
/// reported it before — the short "Allaqachon yuborilgan" sheet. Sending
/// keeps the sheet open and swaps its content for the thank-you.
Future<void> showReportSheet(BuildContext context, {required ReportTarget target}) async {
  final result = await TopildiLoader.run<Either<Failure, bool>>(
    context,
    task: () => getIt<CheckReported>()((type: target.type, targetId: target.id)),
    icon: Symbols.flag_rounded,
    label: tr('Tekshirilmoqda…'),
    errorLabel: tr('Shikoyat qilib boʻlmadi'),
    failureOf: (r) => r.getLeft().toNullable(),
  );
  if (result == null || !context.mounted) return;
  final already = result.getOrElse((_) => false);
  await showGlassSheet<void>(
    context,
    label: tr('Shikoyat qilish'),
    builder: (_) => already ? _AlreadySent(target: target) : _ReportSheet(target: target),
  );
}

/// The label of a reason; "Soxta eʼlon" is an "Aldov" inside a chat.
String _reasonLabel(ReportReason reason, ReportTargetType type) => switch (reason) {
  ReportReason.spam => tr('Spam'),
  ReportReason.fake => type == ReportTargetType.chat ? tr('Aldov') : tr('Soxta eʼlon'),
  ReportReason.scam => tr('Firibgarlik'),
  ReportReason.offensive => tr('Haqoratli'),
  ReportReason.other => tr('Boshqa'),
};

IconData _reasonIcon(ReportReason reason) => switch (reason) {
  ReportReason.spam => Symbols.campaign_rounded,
  ReportReason.fake => Symbols.content_copy_rounded,
  ReportReason.scam => Symbols.money_off_rounded,
  ReportReason.offensive => Symbols.sentiment_very_dissatisfied_rounded,
  ReportReason.other => Symbols.more_horiz_rounded,
};

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.target});

  final ReportTarget target;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _comment = TextEditingController();
  final _commentFocus = FocusNode();
  ReportReason? _reason;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _comment.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comment.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null) return;
    FocusScope.of(context).unfocus();
    final result = await TopildiLoader.run<Either<Failure, void>>(
      context,
      task: () => getIt<SubmitReport>()(
        SubmitReportParams(target: widget.target, reason: reason, comment: _comment.text),
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
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _sent ? const _Sent() : _form(context),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant;
    final count = _comment.text.characters.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('Shikoyat qilish'),
                  style: TextStyle(fontSize: 22, letterSpacing: -0.4, color: cs.onSurface).inter(FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              _CloseButton(onTap: () => Navigator.of(context).maybePop()),
            ],
          ),
          const SizedBox(height: 12),
          _TargetCard(target: widget.target),
          const SizedBox(height: 18),
          _Label(tr('SABAB')),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in ReportReason.values)
                _ReasonChip(
                  label: _reasonLabel(r, widget.target.type),
                  icon: _reasonIcon(r),
                  selected: _reason == r,
                  onTap: () => setState(() => _reason = r),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Label(tr('IZOH · IXTIYORIY'))),
              Text(
                '$count / $maxReportComment',
                style: TextStyle(fontSize: 13, color: muted).inter(FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CommentField(controller: _comment, focusNode: _commentFocus),
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
          const SizedBox(height: 12),
          TSheetButton(label: tr('Yuborish'), onTap: _reason == null ? null : _send),
        ],
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

/// SH6: this person has reported the same target before.
class _AlreadySent extends StatelessWidget {
  const _AlreadySent({required this.target});

  final ReportTarget target;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(18)),
                child: Icon(Symbols.schedule_rounded, size: 28, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Allaqachon yuborilgan'),
                      style: TextStyle(fontSize: 19, color: cs.onSurface).inter(FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target.type == ReportTargetType.listing
                          ? tr('Bu eʼlonga shikoyatingiz bor. Moderator koʻrib chiqmoqda.')
                          : tr('Bu suhbatga shikoyatingiz bor. Moderator koʻrib chiqmoqda.'),
                      style: TextStyle(fontSize: 14, height: 19 / 14, color: cs.onSurfaceVariant).inter(FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TSheetButton(
            label: tr('Yopish'),
            tone: TSheetButtonTone.secondary,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
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
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          PhotoPlaceholder(
            icon: target.category.icon,
            tint: target.tint,
            path: target.photoUrl,
            width: 40,
            height: 40,
            iconSize: 22,
            radius: 12,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: cs.onSurface).inter(FontWeight.w700),
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

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimaryContainer : cs.secondary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.only(left: 12, right: 16),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: selected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(fontSize: 15, color: fg).inter(selected ? FontWeight.w700 : FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: color, width: width),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 84),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        minLines: 3,
        maxLines: 6,
        maxLength: maxReportComment,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(fontSize: 15, height: 20 / 15, color: cs.onSurface).inter(FontWeight.w400),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: cs.surfaceContainerLowest,
          hintText: tr('Qisqacha yozing — moderatorga yordam beradi'),
          hintStyle: TextStyle(fontSize: 15, height: 20 / 15, color: cs.outline).inter(FontWeight.w400),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: border(cs.outlineVariant, 1),
          enabledBorder: border(cs.outlineVariant, 1),
          focusedBorder: border(cs.primary, 2),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: tr('Yopish'),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 44 tall for the finger, 36 of it drawn.
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: cs.surfaceContainerHigh, shape: BoxShape.circle),
              child: Icon(Symbols.close_rounded, size: 20, color: cs.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
