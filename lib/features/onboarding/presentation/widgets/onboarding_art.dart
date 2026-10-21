import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/l10n/tr.dart';

/// 300×300 illustrations for the three onboarding slides.
class OnboardingArt extends StatelessWidget {
  const OnboardingArt({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final ts = context.ts;
    final shadow = [BoxShadow(color: cs.scrim.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, 10))];

    Widget dot(double size, Color c) =>
        Container(width: size, height: size, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
    Widget bar(double w) =>
        Container(width: w, height: 8, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)));
    Widget card({required Widget child, EdgeInsets padding = const EdgeInsets.all(10), double radius = 16}) => Container(
          padding: padding,
          decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(radius), boxShadow: shadow),
          child: child,
        );
    Widget row(int tint, double w1, double w2) => card(
          padding: const EdgeInsets.all(8),
          radius: 12,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: ts.placeholder(tint), borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bar(w1), const SizedBox(height: 6), bar(w2)]),
            ],
          ),
        );

    final (bg, children) = switch (index) {
      0 => (
          cs.primaryContainer,
          <Widget>[
            Positioned(
              left: 62,
              top: 58,
              child: Transform.rotate(
                angle: -0.087,
                child: SizedBox(
                  width: 176,
                  child: card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 110,
                          decoration: BoxDecoration(color: ts.placeholder(2), borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Icon(Symbols.backpack_rounded, size: 44, color: ts.placeholderIcon, weight: 300)),
                        ),
                        const SizedBox(height: 8),
                        const TypeBadge(isFound: true, size: BadgeSize.small),
                        const SizedBox(height: 8),
                        bar(120),
                        const SizedBox(height: 8),
                        bar(80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 34,
              bottom: 50,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle, boxShadow: shadow),
                child: Icon(Symbols.photo_camera_rounded, size: 32, color: cs.onPrimary),
              ),
            ),
            Positioned(left: 30, bottom: 70, child: dot(14, tc.found)),
            Positioned(right: 60, top: 30, child: dot(10, cs.primary)),
          ],
        ),
      1 => (
          tc.lostContainer,
          <Widget>[
            Positioned(
              left: 40,
              top: 70,
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  row(0, 90, 60),
                  const SizedBox(height: 10),
                  Padding(padding: const EdgeInsets.only(left: 24), child: row(2, 80, 50)),
                  const SizedBox(height: 10),
                  row(1, 96, 40),
                ],
              ),
            ),
            // Magnifying glass.
            Positioned(
              right: 26,
              top: 120,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: tc.lost, width: 6),
                  boxShadow: shadow,
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 206,
              child: Transform.rotate(
                angle: -0.7,
                child: Container(
                  width: 14,
                  height: 44,
                  decoration: BoxDecoration(color: tc.lost, borderRadius: BorderRadius.circular(7)),
                ),
              ),
            ),
            Positioned(left: 36, top: 44, child: dot(12, cs.primary)),
          ],
        ),
      _ => (
          tc.successContainer,
          <Widget>[
            Positioned(
              left: 90,
              top: 70,
              child: Icon(Symbols.verified_user_rounded, size: 130, color: tc.success, weight: 300),
            ),
            Positioned(
              left: 22,
              top: 52,
              child: _Bubble(
                icon: Symbols.lock_rounded,
                label: tr('Yashirin belgi'),
                bg: cs.surfaceContainerLowest,
                fg: cs.onSurface,
                shadow: shadow,
                tail: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 56,
              child: _Bubble(
                icon: Symbols.check_rounded,
                label: tr('Qaytarildi'),
                bg: cs.primary,
                fg: cs.onPrimary,
                shadow: shadow,
                tail: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ],
        ),
    };

    return ExcludeSemantics(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.shadow,
    required this.tail,
  });

  final IconData icon;
  final String label;
  final Color bg, fg;
  final List<BoxShadow> shadow;
  final BorderRadius tail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: tail, boxShadow: shadow),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
