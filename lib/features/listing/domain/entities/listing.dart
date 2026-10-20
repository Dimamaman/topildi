import 'package:equatable/equatable.dart';

import '../../../../core/location/geo_point.dart';

enum ListingType { found, lost }

enum ItemCategory { documents, phones, keys, wallets, bags, electronics, clothes, kids, other }

enum DatePeriod { today, week, month, custom }

enum ListingStatus { active, returned }

/// Public profile of another user. Never carries a phone number.
class PublicUser extends Equatable {
  const PublicUser({required this.id, required this.displayName, this.returnedCount = 0});

  final String id;

  /// First name + surname initial, e.g. "Dilshod A.".
  final String displayName;
  final int returnedCount;

  @override
  List<Object?> get props => [id, displayName, returnedCount];
}

/// Public listing. Deliberately has no hidden detail and no exact location:
/// [areaName] is an approximate (~300 m) area.
class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.areaName,
    required this.happenedAt,
    required this.author,
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

  final String id;
  final String city, district;
  final ListingType type;
  final ItemCategory category;
  final String title, description, areaName;
  final DateTime happenedAt;
  final PublicUser author;
  final int photoCount;

  /// Photo locations (local paths until uploads exist). Empty → placeholders.
  final List<String> photos;

  int get galleryCount => photos.isEmpty ? photoCount : photos.length;

  String? photoAt(int i) => i < photos.length ? photos[i] : null;

  /// Placeholder tint index until real photos exist.
  final int tint;
  final ListingStatus status;

  bool get isFound => type == ListingType.found;

  GeoPoint get area => GeoPoint(lat, lng);

  @override
  List<Object?> get props =>
      [id, type, category, title, description, areaName, happenedAt, author, photoCount, photos, tint, status, city, district, lat, lng];
}

/// Feed filters chosen in the Filters sheet (and the category chips).
class ListingFilter extends Equatable {
  const ListingFilter({
    this.categories = const {},
    this.city = 'Toshkent',
    this.district,
    this.period = DatePeriod.month,
    this.from,
    this.to,
  });

  /// Empty = all categories.
  final Set<ItemCategory> categories;
  final String city;

  /// null = all districts of [city].
  final String? district;
  final DatePeriod period;

  /// Used when [period] is [DatePeriod.custom].
  final DateTime? from, to;

  /// Inclusive start of the period, relative to [now].
  DateTime start(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (period) {
      DatePeriod.today => today,
      DatePeriod.week => today.subtract(const Duration(days: 6)),
      DatePeriod.month => today.subtract(const Duration(days: 29)),
      DatePeriod.custom => from ?? today.subtract(const Duration(days: 29)),
    };
  }

  /// Exclusive end of the period.
  DateTime end(DateTime now) {
    final base = period == DatePeriod.custom && to != null ? to! : now;
    return DateTime(base.year, base.month, base.day + 1);
  }

  bool get isDefault => this == const ListingFilter();

  ListingFilter copyWith({
    Set<ItemCategory>? categories,
    String? city,
    String? Function()? district,
    DatePeriod? period,
    DateTime? from,
    DateTime? to,
  }) =>
      ListingFilter(
        categories: categories ?? this.categories,
        city: city ?? this.city,
        district: district != null ? district() : this.district,
        period: period ?? this.period,
        from: from ?? this.from,
        to: to ?? this.to,
      );

  @override
  List<Object?> get props => [categories, city, district, period, from, to];
}

class ListingQuery extends Equatable {
  const ListingQuery({required this.type, this.filter = const ListingFilter(), this.search = ''});

  final ListingType type;
  final ListingFilter filter;
  final String search;

  @override
  List<Object?> get props => [type, filter, search];
}

class ListingPage extends Equatable {
  const ListingPage({required this.items, required this.total});

  final List<Listing> items;
  final int total;

  @override
  List<Object?> get props => [items, total];
}
