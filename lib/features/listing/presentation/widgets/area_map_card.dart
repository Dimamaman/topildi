import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/location/geo_point.dart';
import '../../../../core/map/map_tiles.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';

/// Approximate-area card: stylised map thumbnail + area name + time.
/// Never shows an exact pin, only the ~300 m area.
class AreaMapCard extends StatelessWidget {
  const AreaMapCard({super.key, required this.area, required this.time, required this.point});

  final String area, time;
  final GeoPoint point;

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
          Positioned(left: 0, top: 0, bottom: 0, width: 108, child: AreaMiniMap(point: point, zoom: 13)),
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

/// Small non-interactive map with the ~300 m area circle.
class AreaMiniMap extends StatelessWidget {
  const AreaMiniMap({super.key, required this.point, this.zoom = 14});

  final GeoPoint point;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final center = LatLng(point.lat, point.lng);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            backgroundColor: context.ts.map,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            const TopildiTileLayer(),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: GeoPoint.areaMeters / 2,
                  useRadiusInMeter: true,
                  color: cs.primary.withValues(alpha: 0.18),
                  borderColor: cs.primary.withValues(alpha: 0.6),
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
