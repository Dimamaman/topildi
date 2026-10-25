import 'package:equatable/equatable.dart';

import '../../../../core/config/features.dart';
import '../../../../core/location/geo_point.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../../../core/l10n/tr.dart';

enum DraftDay { today, yesterday, other }

/// Listing being composed across Create1–3. [hiddenDetail] stays private:
/// it is stored for the author and never put on the public [Listing].
class CreateDraft extends Equatable {
  const CreateDraft({
    this.type = ListingType.found,
    this.photos = const [],
    this.title = '',
    this.category,
    this.description = '',
    this.hiddenDetail = '',
    this.areaName,
    this.point,
    this.district,
    this.day = DraftDay.today,
    this.date,
    this.hour = 9,
    this.minute = 40,
  });

  static const maxPhotos = 6;
  static const maxDescription = 500;

  final ListingType type;

  /// Local paths of picked photos; the first one is the main photo.
  final List<String> photos;
  final String title;
  final ItemCategory? category;
  final String description, hiddenDetail;

  /// Approximate (~300 m) area name chosen on the map.
  final String? areaName;

  /// Centre of the chosen ~300 m cell (already approximated).
  final GeoPoint? point;
  final String? district;
  final DraftDay day;

  /// Explicit date when [day] is [DraftDay.other].
  final DateTime? date;
  final int hour, minute;

  bool get isFound => type == ListingType.found;

  DateTime happenedAt(DateTime now) {
    final base = switch (day) {
      DraftDay.today => now,
      DraftDay.yesterday => now.subtract(const Duration(days: 1)),
      DraftDay.other => date ?? now,
    };
    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  CreateDraft copyWith({
    ListingType? type,
    List<String>? photos,
    String? title,
    ItemCategory? category,
    String? description,
    String? hiddenDetail,
    String? areaName,
    GeoPoint? point,
    String? district,
    DraftDay? day,
    DateTime? date,
    int? hour,
    int? minute,
  }) =>
      CreateDraft(
        type: type ?? this.type,
        photos: photos ?? this.photos,
        title: title ?? this.title,
        category: category ?? this.category,
        description: description ?? this.description,
        hiddenDetail: hiddenDetail ?? this.hiddenDetail,
        areaName: areaName ?? this.areaName,
        point: point ?? this.point,
        district: district ?? this.district,
        day: day ?? this.day,
        date: date ?? this.date,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  @override
  List<Object?> get props =>
      [type, photos, title, category, description, hiddenDetail, areaName, point, district, day, date, hour, minute];
}

/// Field-level validation for step 2 and 3. Messages are user-facing.
abstract final class DraftValidator {
  static String? title(CreateDraft d) => d.title.trim().length < 3 ? tr('Sarlavhani kiriting (kamida 3 ta belgi)') : null;

  static String? category(CreateDraft d) => d.category == null ? tr('Kategoriyani tanlang') : null;

  /// Required for found items: it is how the owner proves ownership.
  static String? hiddenDetail(CreateDraft d) =>
      d.isFound && d.hiddenDetail.trim().length < 5 ? tr('Yashirin belgini yozing: egasini shu orqali tekshirasiz') : null;

  static String? area(CreateDraft d) => d.areaName == null || d.point == null
      ? (Features.map ? tr('Xaritada joyni belgilang') : tr('Joyni belgilang'))
      : null;

  static bool detailsValid(CreateDraft d) => title(d) == null && category(d) == null && hiddenDetail(d) == null;

  static bool isComplete(CreateDraft d) => detailsValid(d) && area(d) == null;
}
