import 'package:fpdart/fpdart.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import 'geo_point.dart';

enum LocationProblem { serviceOff, denied, deniedForever, unavailable }

extension LocationProblemText on LocationProblem {
  String get message => switch (this) {
        LocationProblem.serviceOff => 'Joylashuv xizmati oʻchirilgan. Sozlamalardan yoqing.',
        LocationProblem.denied => 'Joylashuvga ruxsat berilmadi.',
        LocationProblem.deniedForever => 'Joylashuvga ruxsat yoʻq. Uni sozlamalardan yoqing.',
        LocationProblem.unavailable => 'Joylashuvni aniqlab boʻlmadi.',
      };
}

abstract interface class LocationService {
  /// Asks for permission when needed. Exact position: keep it on-device and
  /// call [GeoPoint.approximate] before sharing.
  Future<Either<LocationProblem, GeoPoint>> current();

  Future<void> openSettings();
}

class AreaInfo {
  const AreaInfo({required this.name, this.district});

  /// Short public label, e.g. "Chilonzor-9" or a street name.
  final String name;
  final String? district;
}

abstract interface class Geocoder {
  /// Area label for an (already approximated) point; null if unknown.
  Future<AreaInfo?> areaFor(GeoPoint point);
}

@prod
@LazySingleton(as: LocationService)
class DeviceLocationService implements LocationService {
  @override
  Future<Either<LocationProblem, GeoPoint>> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return left(LocationProblem.serviceOff);
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return left(LocationProblem.denied);
      if (permission == LocationPermission.deniedForever) return left(LocationProblem.deniedForever);
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
      );
      return right(GeoPoint(p.latitude, p.longitude));
    } catch (_) {
      return left(LocationProblem.unavailable);
    }
  }

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();
}

@prod
@LazySingleton(as: Geocoder)
class DeviceGeocoder implements Geocoder {
  final _geocoding = gc.Geocoding();

  @override
  Future<AreaInfo?> areaFor(GeoPoint point) async {
    try {
      final marks = await _geocoding.placemarkFromCoordinates(point.lat, point.lng);
      if (marks.isEmpty) return null;
      final m = marks.first;
      String? clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
      final name = clean(m.subLocality) ?? clean(m.thoroughfare) ?? clean(m.locality);
      if (name == null) return null;
      return AreaInfo(name: name, district: clean(m.subAdministrativeArea) ?? clean(m.subLocality));
    } catch (_) {
      return null;
    }
  }
}

/// Deterministic fakes for widget tests.
@test
@LazySingleton(as: LocationService)
class FakeLocationService implements LocationService {
  @override
  Future<Either<LocationProblem, GeoPoint>> current() async => right(GeoPoint.tashkent);

  @override
  Future<void> openSettings() async {}
}

@test
@LazySingleton(as: Geocoder)
class FakeGeocoder implements Geocoder {
  @override
  Future<AreaInfo?> areaFor(GeoPoint point) async =>
      const AreaInfo(name: 'Chilonzor-9, metro bekati yonida', district: 'Chilonzor');
}
