import 'dart:math' as math;

import 'package:equatable/equatable.dart';

class GeoPoint extends Equatable {
  const GeoPoint(this.lat, this.lng);

  /// Chilonzor metro: fallback when location is unavailable.
  static const tashkent = GeoPoint(41.2856, 69.2034);

  /// Grid step for public locations (~300 m).
  static const areaMeters = 300.0;

  final double lat, lng;

  /// Snaps to the centre of a ~300 m grid cell. Everything shown to other
  /// users goes through this, so an exact pin is never published.
  GeoPoint approximate() {
    const latStep = areaMeters / 111320.0;
    double snap(double v, double step) => ((v / step).floor() + 0.5) * step;
    // Longitude step uses the snapped row latitude so snapping is idempotent.
    final rowLat = snap(lat, latStep);
    final lngStep = areaMeters / (111320.0 * math.cos(rowLat * math.pi / 180));
    return GeoPoint(rowLat, snap(lng, lngStep));
  }

  /// Great-circle distance in metres.
  double distanceTo(GeoPoint o) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(o.lat - lat);
    final dLng = rad(o.lng - lng);
    final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat)) * math.cos(rad(o.lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  @override
  List<Object?> get props => [lat, lng];
}

/// "350 m" · "1,2 km".
String formatDistance(double m) {
  if (m < 1000) return '${math.max(50, (m / 50).round() * 50)} m';
  return '${(m / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}
