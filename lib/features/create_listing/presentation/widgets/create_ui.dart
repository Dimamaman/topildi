import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/t_text.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../../core/l10n/tr.dart';
import '../pages/create_flow_page.dart';
import '../../../../core/theme/topildi_theme.dart';

/// Colours of the create flow ("live card" design) that are not in the
/// colour scheme, light and dark.
class CreateColors {
  const CreateColors._({
    required this.glow,
    required this.segment,
    required this.segmentThumb,
    required this.progressRest,
    required this.cardPhoto,
    required this.cardPhotoIcon,
    required this.bar,
    required this.barSoft,
    required this.dashed,
  });

  /// Light behind the top of the page and the preview card.
  final Color glow;
  final Color segment, segmentThumb, progressRest;

  /// Preview photo area with nothing to show yet.
  final Color cardPhoto, cardPhotoIcon;

  /// Grey bars standing in for the title and meta line.
  final Color bar, barSoft;

  /// "6 tagacha rasm" dashed frame.
  final Color dashed;

  static const _light = CreateColors._(
    glow: Color(0xFFE3EBFC),
    segment: Color(0xFFE6E9EF),
    segmentThumb: Color(0xFFFFFFFF),
    progressRest: Color(0xFFD5DBE6),
    cardPhoto: Color(0xFFEEF1F6),
    cardPhotoIcon: Color(0xFFB4BDCC),
    bar: Color(0xFFE6E9EF),
    barSoft: Color(0xFFEEF1F6),
    dashed: Color(0xFFC8CED9),
  );

  static const _dark = CreateColors._(
    glow: Color(0xFF111214),
    segment: Color(0xFF111214),
    segmentThumb: Color(0xFF26282D),
    progressRest: Color(0xFF26282D),
    cardPhoto: Color(0xFF17181B),
    cardPhotoIcon: Color(0xFF5F6672),
    bar: Color(0xFF26282D),
    barSoft: Color(0xFF26282D),
    dashed: Color(0xFF5F6672),
  );

  static CreateColors of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

/// Page colour with the primary light at the top centre.
class CreateBackground extends StatelessWidget {
  const CreateBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final glow = CreateColors.of(context).glow;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        gradient: RadialGradient(
          center: Alignment.topCenter,
          // ≈50% of the way to the farthest corner on 390×844.
          radius: 1.1,
          colors: [glow, glow.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Section title (15 w700) with an optional value on the right (13, muted);
/// the value is tappable when [onValueTap] is set.
class CreateSectionLabel extends StatelessWidget {
  const CreateSectionLabel({
    super.key,
    required this.label,
    this.value,
    this.onValueTap,
    this.onValuePick,
    this.error = false,
  });

  final String label;
  final String? value;
  final VoidCallback? onValueTap;

  /// Opens a menu from the value, which then shows a chevron.
  final void Function(BuildContext anchor)? onValuePick;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final v = value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                label,
                style: text.titleSmall!
                    .copyWith(fontSize: 15, height: 20 / 15, color: error ? cs.error : cs.onSurface)
                    .inter(FontWeight.w700),
              ),
            ),
          ),
          if (v != null)
            Builder(
              builder: (anchor) {
                final pick = onValuePick;
                final label = Text(
                  v,
                  style: text.bodySmall!
                      .copyWith(fontSize: 13, height: 18 / 13, color: pick != null ? cs.primary : cs.onSurfaceVariant)
                      .inter(pick != null ? FontWeight.w600 : FontWeight.w400),
                );
                return GestureDetector(
                  onTap: pick != null ? () => pick(anchor) : onValueTap,
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    button: pick != null || onValueTap != null,
                    child: pick == null
                        ? label
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              label,
                              const SizedBox(width: 2),
                              Icon(Symbols.expand_more_rounded, size: 18, color: cs.primary),
                            ],
                          ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// 44-high capsule chip: primary when selected, white with a hairline
/// otherwise; [accent] is the "Aniqlash" style (primary container).
class CreateChip extends StatelessWidget {
  const CreateChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
    this.accent = false,
    this.fontSize = 14,
  });

  final String label;
  final bool selected, accent;
  final VoidCallback? onTap;
  final IconData? icon;

  /// Replaces [icon] (e.g. a spinner).
  final Widget? leading;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, iconColor, border) = selected
        ? (context.tc.primaryFill, cs.onPrimary, cs.onPrimary, null)
        : accent
        ? (cs.primaryContainer, cs.onPrimaryContainer, cs.onPrimaryContainer, null)
        : (cs.surfaceContainerLowest, cs.secondary, cs.primary, cs.outlineVariant);
    final lead = leading ?? (icon != null ? Icon(icon, size: 18, color: iconColor) : null);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          padding: EdgeInsets.only(left: lead != null ? 10 : 16, right: lead != null ? 14 : 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: border == null ? null : Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lead != null) ...[lead, const SizedBox(width: 6)],
              Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge!
                    .copyWith(fontSize: fontSize, height: 20 / fontSize, color: fg)
                    .inter(accent && !selected ? FontWeight.w700 : FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White capsule input: small label over the value, a hairline that turns
/// into a 2px primary ring on focus and red on [error].
class CreateField extends StatefulWidget {
  const CreateField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.focusNode,
    this.maxLength,
    this.icon,
    this.error,
    this.textInputAction,
  });

  final String label, hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final int? maxLength;
  final IconData? icon;
  final String? error;
  final TextInputAction? textInputAction;

  @override
  State<CreateField> createState() => _CreateFieldState();
}

class _CreateFieldState extends State<CreateField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_changed);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final error = widget.error;
    final focused = _focus.hasFocus;
    final (borderColor, borderWidth) = error != null
        ? (cs.error, 2.0)
        : focused
        ? (cs.primary, 2.0)
        : (cs.outlineVariant, 1.0);
    final value = text.bodyLarge!.copyWith(fontSize: 17, height: 22 / 17, color: cs.onSurface).inter(FontWeight.w500);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _focus.requestFocus,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: EdgeInsets.fromLTRB(widget.icon != null ? 18 : 22, 10, 18, 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: borderWidth, strokeAlign: BorderSide.strokeAlignInside),
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: text.labelSmall!
                            .copyWith(
                              fontSize: 12,
                              height: 16 / 12,
                              color: error != null ? cs.error : cs.onSurfaceVariant,
                            )
                            .inter(FontWeight.w600),
                      ),
                      TextField(
                        controller: widget.controller,
                        focusNode: _focus,
                        onChanged: widget.onChanged,
                        maxLength: widget.maxLength,
                        textInputAction: widget.textInputAction ?? TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        // The steps do not shrink for the keyboard: keep the
                        // caret above it and the floating button.
                        scrollPadding: EdgeInsets.fromLTRB(20, 20, 20, createFormBottomPadding(context)),
                        style: value,
                        cursorColor: cs.primary,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          counterText: '',
                          contentPadding: const EdgeInsets.only(top: 2),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          hintText: widget.hint,
                          hintMaxLines: 1,
                          hintStyle: value.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) CreateError(error),
      ],
    );
  }
}

/// Red message under a field or a row of chips.
class CreateError extends StatelessWidget {
  const CreateError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(fontSize: 13, height: 18 / 13, color: cs.error).inter(FontWeight.w500),
        ),
      ),
    );
  }
}

/// Icon + 13px note, e.g. the photo warning.
class CreateNote extends StatelessWidget {
  const CreateNote({super.key, required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: c),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(fontSize: 13, height: 18 / 13, color: c).inter(FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

/// 44 glass circle (close / back).
class CreateGlassButton extends StatelessWidget {
  const CreateGlassButton({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox.square(
            dimension: 44,
            child: GlassSurface(
              color: context.glass.button,
              child: Icon(icon, size: 24, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

/// 56px primary capsule with an icon after the label. Null [onTap]:
/// dimmed and not tappable.
class CreatePrimaryButton extends StatelessWidget {
  const CreatePrimaryButton({super.key, required this.label, this.icon, this.leadingIcon, required this.onTap});

  final String label;
  final IconData? icon;

  /// Icon before the label instead ("Soʻrov yuborish").
  final IconData? leadingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: onTap == null ? 0.45 : 1,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: context.tc.primaryFill,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: context.primaryGlow(0.28),
                  offset: const Offset(0, 12),
                  blurRadius: 28,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[Icon(leadingIcon, size: 20, color: cs.onPrimary), const SizedBox(width: 8)],
                  Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelLarge!
                        .copyWith(fontSize: 17, height: 22 / 17, color: cs.onPrimary)
                        .inter(FontWeight.w600),
                  ),
                  if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20, color: cs.onPrimary)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Chiqasizmi?" — true when the user chose to leave the unsaved listing.
Future<bool> confirmLeaveCreate(BuildContext context) => TFeedback.confirm(
  context,
  title: tr('Chiqasizmi?'),
  body: tr('Eʼlon saqlanmaydi.'),
  confirmLabel: tr('Chiqish'),
  cancelLabel: tr('Bekor qilish'),
  destructive: true,
);

/// "Bugun, 09:40" · "Kecha, 18:30" · "19-oktabr, 05:25".
String createWhenLabel(DateTime at, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(at.year, at.month, at.day);
  final label = day == today
      ? tr('Bugun')
      : day == today.subtract(const Duration(days: 1))
      ? tr('Kecha')
      : TDate.dayMonth(at);
  return '$label, ${TDate.time(at)}';
}

/// Icons used in more than one step.
abstract final class CreateIcons {
  static const next = Symbols.arrow_forward_rounded;
  static const review = Symbols.visibility_rounded;
}
