import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/topildi_theme.dart';

enum BadgeSize { small, medium }

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg, this.icon, this.size = BadgeSize.medium, this.weight = FontWeight.w600});

  final String label;
  final Color bg, fg;
  final IconData? icon;
  final BadgeSize size;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final small = size == BadgeSize.small;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10, vertical: small ? 3 : 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(TRadius.xs)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg, weight: 700), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: small ? 12 : 13, fontWeight: weight, color: fg, height: 16 / 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Topilgan" / "Yoʻqolgan" badge. Always carries text, never colour alone.
class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.isFound, this.size = BadgeSize.medium});

  final bool isFound;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return _Badge(
      label: isFound ? 'Topilgan' : 'Yoʻqolgan',
      bg: isFound ? tc.foundContainer : tc.lostContainer,
      fg: isFound ? tc.found : tc.lost,
      size: size,
    );
  }
}

/// Neutral category badge (Hamyonlar, Kalitlar, …).
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.label, this.size = BadgeSize.medium});

  final String label;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _Badge(label: label, bg: cs.surfaceContainerHigh, fg: cs.secondary, size: size, weight: FontWeight.w500);
  }
}

enum StatusKind { active, pending, accepted, rejected, returned }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.kind, this.label, this.size = BadgeSize.medium});

  final StatusKind kind;
  final String? label;
  final BadgeSize size;

  static String defaultLabel(StatusKind kind) => switch (kind) {
        StatusKind.active => 'Faol',
        StatusKind.pending => 'Kutilmoqda',
        StatusKind.accepted => 'Qabul qilindi',
        StatusKind.rejected => 'Rad etildi',
        StatusKind.returned => 'Qaytarildi',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final (bg, fg, icon) = switch (kind) {
      StatusKind.active => (cs.primaryContainer, cs.onPrimaryContainer, null),
      StatusKind.pending => (tc.warningContainer, tc.warning, null),
      StatusKind.accepted => (tc.successContainer, tc.success, Symbols.check_rounded),
      StatusKind.rejected => (cs.errorContainer, cs.onErrorContainer, null),
      StatusKind.returned => (tc.successContainer, tc.success, Symbols.check_rounded),
    };
    return _Badge(label: label ?? defaultLabel(kind), bg: bg, fg: fg, icon: icon, size: size);
  }
}
