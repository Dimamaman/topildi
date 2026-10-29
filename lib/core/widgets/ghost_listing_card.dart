import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum GhostCardSize {
  /// 96×112 — the Profil "Hali eʼlon bermagansiz" card.
  small,

  /// Fills its box (270×236 in the design) — "Mening eʼlonlarim" empty tabs.
  large,
}

/// Faint dashed sample listing — photo slot with [icon] and skeleton lines —
/// showing where the user's listing will sit. Purely decorative; the caller
/// tilts and animates it.
class GhostListingCard extends StatelessWidget {
  const GhostListingCard({super.key, this.size = GhostCardSize.large, this.icon = Symbols.add_a_photo_rounded});

  final GhostCardSize size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final small = size == GhostCardSize.small;
    final radius = small ? 20.0 : 28.0;
    final line1 = dark ? const Color(0xFF222C40) : const Color(0xFFE3E8F0);
    final line2 = dark ? const Color(0xFF1D2638) : const Color(0xFFECEFF5);
    final photo = Container(
      height: small ? 66 : 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? (small ? const Color(0xFF1D2638) : const Color(0xFF182031)) : const Color(0xFFEAEEF5),
        borderRadius: BorderRadius.circular(small ? 14 : 20),
      ),
      child: Icon(icon, size: small ? 26 : 44, color: dark ? const Color(0xFF3A4A6E) : const Color(0xFFB4BDCC)),
    );
    final card = SizedBox(
      width: small ? 96 : null,
      height: small ? 112 : null,
      child: CustomPaint(
        painter: DashedRRectPainter(
          color: dark ? const Color(0xFF2A3550) : const Color(0xFFC7D2E6),
          fill: dark
              ? (small ? const Color(0x990F1420) : const Color(0x99182031))
              : (small ? const Color(0xB3F4F6FA) : const Color(0x99FFFFFF)),
          radius: radius,
          width: 2,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: LayoutBuilder(
            builder: (context, c) => small
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        photo,
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                          child: _bar((c.maxWidth - 12) * 0.7, 8, line1),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                          child: _bar((c.maxWidth - 12) * 0.44, 6, line2),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.all(10), child: photo),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bar((c.maxWidth - 36) * 0.72, 14, line1),
                            const SizedBox(height: 9),
                            _bar((c.maxWidth - 36) * 0.48, 10, line2),
                            const SizedBox(height: 12),
                            _bar(64, 22, Theme.of(context).colorScheme.primaryContainer),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    return ExcludeSemantics(child: card);
  }

  static Widget _bar(double w, double h, Color c) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(h / 2)),
  );
}

/// Filled rounded rect with a dashed outline drawn inside its bounds.
class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter({required this.color, required this.fill, required this.radius, required this.width});

  final Color color, fill;
  final double radius, width;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = fill);
    final dash = width * 3, gap = width * 2;
    final path = Path()..addRRect(rrect.deflate(width / 2));
    final out = Path();
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap) {
        out.addPath(m.extractPath(d, math.min(d + dash, m.length)), Offset.zero);
      }
    }
    canvas.drawPath(
      out,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(DashedRRectPainter old) =>
      old.color != color || old.fill != fill || old.radius != radius || old.width != width;
}
