import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/topildi_theme.dart';

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

  /// Two-button confirm dialog. Returns true when the user confirms.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    String cancelLabel = 'Yoʻq',
    bool destructive = false,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: Theme.of(ctx).textTheme.titleLarge!.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(body, style: Theme.of(ctx).textTheme.bodyMedium!.copyWith(color: cs.secondary, height: 1.45)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: destructive
                ? TextButton.styleFrom(overlayColor: Colors.transparent, foregroundColor: cs.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
