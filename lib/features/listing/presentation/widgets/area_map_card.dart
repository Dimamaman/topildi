import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';

/// Approximate-area card: stylised map thumbnail + area name + time.
/// Never shows an exact pin, only the ~300 m area.
class AreaMapCard extends StatelessWidget {
  const AreaMapCard({super.key, required this.area, required this.time});

  final String area, time;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(TRadius.md),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      // Stack sizes to the text column; the map fills the left strip.
      child: Stack(
        children: [
          const Positioned(left: 0, top: 0, bottom: 0, width: 108, child: MapStub(compact: true)),
          Padding(
            padding: const EdgeInsets.fromLTRB(108 + 12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(Symbols.location_on_rounded, area, cs.onSurface, FontWeight.w600),
                const SizedBox(height: 6),
                _row(Symbols.schedule_rounded, time, cs.onSurfaceVariant, FontWeight.w400),
                const SizedBox(height: 6),
                _row(Symbols.radar_rounded, 'Taxminiy hudud, ~300 m', cs.onSurfaceVariant, FontWeight.w400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, Color color, FontWeight weight) => Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: weight))),
        ],
      );
}

/// Decorative map placeholder with roads and an approximate-area circle.
class MapStub extends StatelessWidget {
  const MapStub({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final cs = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        color: ts.map,
        child: LayoutBuilder(
          builder: (context, c) {
            final road = compact ? 6.0 : 10.0;
            final area = compact ? 44.0 : 140.0;
            return Stack(
              children: [
                Positioned(left: 0, right: 0, top: c.maxHeight * 0.38, height: road, child: ColoredBox(color: ts.road)),
                Positioned(top: 0, bottom: 0, left: c.maxWidth * 0.37, width: road, child: ColoredBox(color: ts.road)),
                if (!compact)
                  Positioned(top: 0, bottom: 0, left: c.maxWidth * 0.72, width: road * 0.8, child: ColoredBox(color: ts.road)),
                Center(
                  child: Container(
                    width: area,
                    height: area,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withValues(alpha: 0.16),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.5), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: compact ? 14 : 20,
                      height: compact ? 14 : 20,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surfaceContainerLowest, width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
