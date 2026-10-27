import 'package:flutter/material.dart';

import '../theme/topildi_theme.dart';
import '../l10n/tr.dart';

enum TButtonVariant { primary, secondary, outline, text, danger }

/// Topildi button. Full-width 52dp by default (from theme); [expand] false
/// sizes it to its content.
class TButton extends StatelessWidget {
  const TButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = TButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  const TButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = TButtonVariant.primary;
  const TButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = TButtonVariant.secondary;
  const TButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = TButtonVariant.outline;
  const TButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = TButtonVariant.text;
  const TButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = TButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final TButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onTap = loading ? null : onPressed;
    final minSize = expand ? const Size.fromHeight(TSize.button) : const Size(TSize.tapTarget, TSize.button);

    Widget child(Color fg) {
      if (loading) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg)),
            const SizedBox(width: 10),
            Flexible(child: Text(tr('Yuklanmoqda'), overflow: TextOverflow.ellipsis, maxLines: 1)),
          ],
        );
      }
      final leading = icon != null ? Icon(icon, size: 20) : null;
      final text = Text(label, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center);
      if (leading == null) return text;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 10),
          Flexible(child: text),
        ],
      );
    }

    switch (variant) {
      case TButtonVariant.primary:
        // While loading keep the primary colour instead of the disabled grey.
        return FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            overlayColor: Colors.transparent,
            minimumSize: minSize,
            disabledBackgroundColor: loading ? cs.primary : cs.surfaceContainerHigh,
            disabledForegroundColor: loading ? cs.onPrimary : cs.onSurfaceVariant,
          ),
          child: child(cs.onPrimary),
        );
      case TButtonVariant.secondary:
        return FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            overlayColor: Colors.transparent,
            minimumSize: minSize,
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            disabledBackgroundColor: cs.surfaceContainerHigh,
            disabledForegroundColor: cs.onSurfaceVariant,
          ),
          child: child(cs.onPrimaryContainer),
        );
      case TButtonVariant.outline:
        return OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            overlayColor: Colors.transparent,
            minimumSize: minSize,
            foregroundColor: cs.onSurface,
          ),
          child: child(cs.onSurface),
        );
      case TButtonVariant.danger:
        return OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            overlayColor: Colors.transparent,
            minimumSize: minSize,
            foregroundColor: cs.error,
            side: BorderSide(color: cs.error),
          ),
          child: child(cs.error),
        );
      case TButtonVariant.text:
        return TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            overlayColor: Colors.transparent,
            minimumSize: expand ? const Size.fromHeight(TSize.tapTarget) : null,
          ),
          child: child(cs.primary),
        );
    }
  }
}
