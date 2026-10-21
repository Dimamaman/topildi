import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/location/geo_point.dart';
import '../../../../core/map/map_tiles.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/widgets/glass_surface.dart';

/// Full-screen map of a listing's approximate (~300 m) area. Never shows an
/// exact pin, only a translucent primary circle.
class AreaMapPage extends StatelessWidget {
  const AreaMapPage({super.key, required this.point, required this.area});

  final GeoPoint point;
  final String area;

  static Future<void> open(BuildContext context, {required GeoPoint point, required String area}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AreaMapPage(point: point, area: area),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final center = LatLng(point.lat, point.lng);
    final pad = MediaQuery.paddingOf(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        children: [
          ExcludeSemantics(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                backgroundColor: context.ts.map,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
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
          Positioned(
            left: 16,
            right: 16,
            top: pad.top < 30 ? pad.top + 8 : pad.top,
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Orqaga',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox.square(
                      dimension: 44,
                      child: GlassSurface(child: Icon(Symbols.chevron_left_rounded, size: 24, color: cs.onSurface)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: SizedBox(
                    height: 44,
                    child: GlassSurface(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Symbols.location_on_rounded, size: 20, fill: 1, color: cs.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              area,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium!.copyWith(fontSize: 15, height: 20 / 15).inter(FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: math.max(20, pad.bottom - 14),
            child: GlassSurface(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Symbols.radar_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Taxminiy hudud, ~300 m. Aniq joy koʻrsatilmaydi.',
                      style: text.bodySmall!
                          .copyWith(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant)
                          .inter(FontWeight.w400),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
