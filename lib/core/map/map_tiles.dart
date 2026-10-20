import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:injectable/injectable.dart';

import '../di/injection.dart';

/// Whether to load network tiles. Off in widget tests (no network).
abstract interface class MapTileConfig {
  bool get enabled;
}

@prod
@LazySingleton(as: MapTileConfig)
class NetworkTiles implements MapTileConfig {
  @override
  bool get enabled => true;
}

@test
@LazySingleton(as: MapTileConfig)
class NoTiles implements MapTileConfig {
  @override
  bool get enabled => false;
}

/// OpenStreetMap base layer. Dark theme dims and inverts the tiles so the
/// map does not glare. Swap the URL for a commercial provider before launch
/// (OSM's public servers are not for production traffic).
class TopildiTileLayer extends StatelessWidget {
  const TopildiTileLayer({super.key});

  // Inverts lightness while keeping hue roughly intact.
  static const _dark = ColorFilter.matrix(<double>[
    -0.62, -0.22, -0.07, 0, 235, //
    -0.18, -0.68, -0.07, 0, 235, //
    -0.18, -0.22, -0.52, 0, 235, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    if (!getIt<MapTileConfig>().enabled) return const SizedBox.shrink();
    final layer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.topildi.topildi',
      maxZoom: 19,
    );
    return Theme.of(context).brightness == Brightness.dark ? ColorFiltered(colorFilter: _dark, child: layer) : layer;
  }
}

/// Required OpenStreetMap credit.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    if (!getIt<MapTileConfig>().enabled) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: cs.surfaceContainerLowest.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4)),
        child: Text('© OpenStreetMap', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ),
    );
  }
}
