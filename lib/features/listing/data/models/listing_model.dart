import '../../domain/entities/listing.dart';

/// Storage/DTO shape. Unlike [Listing] it holds the private [hiddenDetail];
/// [toEntity] strips it so public reads can never leak it.
class ListingModel {
  const ListingModel({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.areaName,
    required this.happenedAt,
    required this.author,
    required this.hiddenDetail,
    this.photoCount = 1,
    this.photos = const [],
    this.tint = 0,
    this.status = ListingStatus.active,
    this.city = 'Toshkent',
    this.district = 'Chilonzor',
    this.lat = 41.2856,
    this.lng = 69.2034,
  });

  /// Centre of the approximate (~300 m) area, never the exact pin.
  final double lat, lng;

  final String city, district;

  final String id;
  final ListingType type;
  final ItemCategory category;
  final String title, description, areaName, hiddenDetail;
  final DateTime happenedAt;
  final PublicUser author;
  final int photoCount, tint;
  final List<String> photos;
  final ListingStatus status;

  ListingModel copyWith({ListingStatus? status}) => ListingModel(
        id: id,
        type: type,
        category: category,
        title: title,
        description: description,
        areaName: areaName,
        happenedAt: happenedAt,
        author: author,
        hiddenDetail: hiddenDetail,
        photoCount: photoCount,
        photos: photos,
        tint: tint,
        status: status ?? this.status,
        city: city,
        district: district,
        lat: lat,
        lng: lng,
      );

  Listing toEntity() => Listing(
        id: id,
        type: type,
        category: category,
        title: title,
        description: description,
        areaName: areaName,
        happenedAt: happenedAt,
        author: author,
        photoCount: photoCount,
        photos: photos,
        tint: tint,
        status: status,
        city: city,
        district: district,
        lat: lat,
        lng: lng,
      );
}
