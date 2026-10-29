import 'package:flutter_test/flutter_test.dart';
import 'package:topildi/core/location/geo_point.dart';
import 'package:topildi/features/create_listing/domain/entities/create_draft.dart';
import 'package:topildi/features/listing/domain/entities/regions.dart';

void main() {
  test('every region has a centre', () {
    for (final c in Regions.cities) {
      expect(Regions.regionCenters.containsKey(c), isTrue, reason: c);
    }
  });

  test('locate: Tashkent district, another region, abroad', () {
    expect(Regions.locate(GeoPoint.tashkent), (city: 'Toshkent', district: 'Chilonzor'));
    // Chirchiq is in the region around the capital, not the city.
    expect(Regions.locate(const GeoPoint(41.469, 69.582)), (city: 'Toshkent viloyati', district: null));
    // Registon, Samarqand.
    expect(Regions.locate(const GeoPoint(39.655, 66.976)), (city: 'Samarqand', district: null));
    // Moscow.
    expect(Regions.locate(const GeoPoint(55.75, 37.62)), isNull);
  });

  test('matchDistrict reads geocoder names', () {
    expect(Regions.matchDistrict('Samarqand', 'Urgut tumani'), 'Urgut');
    expect(Regions.matchDistrict('Samarqand', 'Urgut District'), 'Urgut');
    expect(Regions.matchDistrict('Samarqand', 'Samarqand shahri'), 'Samarqand shahri');
    expect(Regions.matchDistrict('Samarqand', 'Chilonzor'), isNull);
    expect(Regions.matchDistrict('Samarqand', null), isNull);
  });

  test('pointOf: district centre in Tashkent, region centre elsewhere', () {
    expect(Regions.pointOf('Toshkent', 'Chilonzor'), const GeoPoint(41.275, 69.204));
    expect(Regions.pointOf('Samarqand', 'Urgut'), const GeoPoint(39.654, 66.976));
  });

  test('another region clears the district', () {
    const d = CreateDraft(title: 'Hamyon', district: 'Chilonzor', point: GeoPoint.tashkent, landmark: 'metro');
    final s = d.withCity('Samarqand');
    expect((s.city, s.district, s.point, s.title, s.landmark), ('Samarqand', null, null, 'Hamyon', 'metro'));
  });
}
