import 'package:equatable/equatable.dart';

import 'listing.dart';

/// One finished story for the feed's "Egasiga qaytdi" strip.
///
/// Deliberately carries no author, no description and no area detail: the
/// strip is proof that the app works, not a page to open. A listing that is
/// over must stop naming the person it belonged to, so the name is dropped
/// here rather than hidden in the widget.
class ReturnedItem extends Equatable {
  const ReturnedItem({
    required this.id,
    required this.title,
    required this.category,
    required this.district,
    required this.returnedAt,
    this.photo,
  });

  final String id;
  final String title;
  final ItemCategory category;

  /// District only — never [Listing.areaName], which is street-level.
  final String district;
  final DateTime returnedAt;

  /// First photo, or null for the category placeholder.
  final String? photo;

  @override
  List<Object?> get props => [id, title, category, district, returnedAt, photo];
}
