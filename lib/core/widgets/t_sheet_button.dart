import 'package:flutter/material.dart';

import '../theme/t_text.dart';
import '../theme/topildi_theme.dart';

/// Which colours a [TSheetButton] wears.
enum TSheetButtonTone {
  /// Blue; the one thing the sheet is for.
  primary,

  /// Red: shikoyat, bloklash.
  danger,

  /// Grey: "Bekor qilish", "Yopish".
  secondary,
}

/// Full-width 54dp pill at the foot of a glass sheet. Disabled it keeps its
/// colour at 45% over the page, as in the design, instead of turning grey —
/// the label stays readable rather than fading with it.
class TSheetButton extends StatelessWidget {
  const TSheetButton({
    super.key,
    required this.label,
    required this.onTap,
    this.tone = TSheetButtonTone.primary,
    this.icon,
  });

  final String label;

  /// null disables the button.
  final VoidCallback? onTap;
  final TSheetButtonTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (baseFill, baseFg) = switch (tone) {
      TSheetButtonTone.primary => (context.tc.primaryFill, cs.onPrimary),
      TSheetButtonTone.danger => (cs.error, cs.onError),
      TSheetButtonTone.secondary => (cs.surfaceContainerHigh, cs.secondary),
    };
    final enabled = onTap != null;
    // Disabled: the fill drops to 45% over the page, the label only to 75% of
    // what is left, so it never sinks into its own capsule.
    final fill = enabled ? baseFill : Color.alphaBlend(baseFill.withValues(alpha: 0.45), cs.surface);
    final fg = enabled ? baseFg : baseFg.withValues(alpha: 0.75);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(999),
            boxShadow: tone == TSheetButtonTone.primary
                ? [
                    BoxShadow(
                      // No blue glow on black.
                      color: dark ? const Color(0x59000000) : fill.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 17, color: fg).inter(FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
