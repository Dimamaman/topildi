import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/topildi_theme.dart';
import '../l10n/tr.dart';
import '../theme/t_text.dart';
import 'glass_surface.dart';

abstract final class TFeedback {
  static void success(BuildContext context, String message, {String? action, VoidCallback? onAction}) =>
      _show(context, message, Symbols.check_rounded, action, onAction, isSuccess: true);

  static void error(BuildContext context, String message, {String? action, VoidCallback? onAction}) =>
      _show(context, message, Symbols.error_rounded, action, onAction);

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    String? action,
    VoidCallback? onAction, {
    bool isSuccess = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Snackbar sits on inverseSurface, so the icon uses the opposite theme's colour.
    final iconColor = isSuccess
        ? (dark ? TopildiColors.light.found : TopildiColors.dark.found)
        : (dark ? const Color(0xFFC2362B) : const Color(0xFFFF8A80));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          action: action == null
              ? null
              : SnackBarAction(label: action, onPressed: onAction ?? () {}, textColor: cs.inversePrimary),
        ),
      );
  }

  /// iOS 26 style alert with two capsule buttons. Returns true when the
  /// user confirms; a tap outside or the back button cancels.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: tr('Bekor qilish'),
      barrierColor: context.glass.scrim,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, _, _) => _GlassAlert(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel ?? tr('Yoʻq'),
        destructive: destructive,
      ),
      // Pops in from slightly larger, like a system alert.
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 1.1, end: 1.0).animate(curved), child: child),
        );
      },
    );
    return result ?? false;
  }
}

class _GlassAlert extends StatelessWidget {
  const _GlassAlert({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  final String title, body, confirmLabel, cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final g = context.glass;
    final text = Theme.of(context).textTheme;
    final cancel = _AlertButton(
      label: cancelLabel,
      fill: g.quiet,
      color: cs.onSurface,
      onTap: () => Navigator.of(context).pop(false),
    );
    // Destructive: red label on the neutral capsule (iOS); otherwise the primary capsule.
    final confirm = _AlertButton(
      label: confirmLabel,
      fill: destructive ? g.quiet : cs.primary,
      color: destructive ? cs.error : cs.onPrimary,
      onTap: () => Navigator.of(context).pop(true),
    );
    final scale = MediaQuery.textScalerOf(context).scale(17) / 17;
    // Side by side when both labels fit, stacked otherwise (long labels, large text).
    final stacked = scale > 1.15 || confirmLabel.length + cancelLabel.length > 24;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: title,
              child: GlassSurface(
                radius: 34,
                blur: 30,
                color: g.menu,
                rim: g.menuRim,
                shadowColor: g.sheetShadow,
                shadowBlur: 60,
                shadowOffset: 20,
                padding: const EdgeInsets.fromLTRB(22, 22, 16, 16),
                child: Material(
                  type: MaterialType.transparency,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            title,
                            style: text.titleMedium!
                                .copyWith(fontSize: 17, height: 22 / 17, color: cs.onSurface)
                                .inter(FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            body,
                            style: text.bodyMedium!.copyWith(fontSize: 15, height: 20 / 15, color: cs.secondary),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (stacked) ...[
                          confirm,
                          const SizedBox(height: 8),
                          cancel,
                        ] else
                          Row(
                            children: [
                              Expanded(child: cancel),
                              const SizedBox(width: 10),
                              Expanded(child: confirm),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 48dp capsule button inside the alert; no ripple, no dimming.
class _AlertButton extends StatelessWidget {
  const _AlertButton({required this.label, required this.fill, required this.color, required this.onTap});

  final String label;
  final Color fill, color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(999)),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge!
                .copyWith(fontSize: 17, height: 22 / 17, color: color)
                .inter(FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
