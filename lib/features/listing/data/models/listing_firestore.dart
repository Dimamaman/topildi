import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/listing.dart';
import 'listing_model.dart';

/// Firestore shape of `topildi_listings/{id}`. The hidden detail is NOT here:
/// it lives in `.../private/secret`, readable by the author only.
/// Coordinates are already the approximate (~300 m) cell centre.
Map<String, Object?> listingToFirestore(ListingModel m, {required List<String> photoUrls}) => {
  'type': m.type.name,
  'category': m.category.name,
  'title': m.title,
  'description': m.description,
  'areaName': m.areaName,
  'city': m.city,
  'district': m.district,
  'lat': m.lat,
  'lng': m.lng,
  'happenedAt': Timestamp.fromDate(m.happenedAt),
  'authorId': m.author.id,
  'authorName': m.author.displayName,
  'authorReturnedCount': m.author.returnedCount,
  'photoUrls': photoUrls,
  'tint': m.tint,
  'status': m.status.name,
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
};

ListingModel listingFromFirestore(String id, Map<String, dynamic> d, {String hiddenDetail = ''}) {
  T byName<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.firstWhere((v) => v.name == name, orElse: () => fallback);
  final photos = [for (final p in (d['photoUrls'] as List?) ?? const []) p as String];
  return ListingModel(
    id: id,
    type: byName(ListingType.values, d['type'], ListingType.found),
    category: byName(ItemCategory.values, d['category'], ItemCategory.other),
    title: d['title'] as String? ?? '',
    description: d['description'] as String? ?? '',
    areaName: d['areaName'] as String? ?? '',
    city: d['city'] as String? ?? 'Toshkent',
    district: d['district'] as String? ?? '',
    lat: (d['lat'] as num?)?.toDouble() ?? 41.2995,
    lng: (d['lng'] as num?)?.toDouble() ?? 69.2401,
    happenedAt: (d['happenedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    author: PublicUser(
      id: d['authorId'] as String? ?? '',
      displayName: d['authorName'] as String? ?? '',
      returnedCount: (d['authorReturnedCount'] as num?)?.toInt() ?? 0,
    ),
    hiddenDetail: hiddenDetail,
    photos: photos,
    photoCount: photos.isEmpty ? 1 : photos.length,
    tint: (d['tint'] as num?)?.toInt() ?? 0,
    status: byName(ListingStatus.values, d['status'], ListingStatus.active),
  );
}
