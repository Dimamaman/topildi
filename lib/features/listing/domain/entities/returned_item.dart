import 'package:equatable/equatable.dart';

import 'listing.dart';

/// One finished story for the feed's "Egasiga qaytdi" strip.
///
/// Carries no description and no area detail, and never the owner: a
/// listing that is over must stop naming the person it belonged to, so the
/// name is dropped here rather than hidden in the widget. The only person it
/// may name is [finderName], and only because that person asked for it.
class ReturnedItem extends Equatable {
  const ReturnedItem({
    required this.id,
    required this.title,
    required this.category,
    required this.district,
    required this.returnedAt,
    this.photo,
    this.finderName,
  });

  final String id;
  final String title;
  final ItemCategory category;

  /// District only — never [Listing.areaName], which is street-level.
  final String district;
  final DateTime returnedAt;

  /// First photo, or null for the category placeholder.
  final String? photo;

  /// The person who returned it, as "Ism F." — only when they consented
  /// (`showNameOnReturns`); null otherwise, which is the default. The owner
  /// is never named here, consent or not.
  final String? finderName;

  @override
  List<Object?> get props => [id, title, category, district, returnedAt, photo, finderName];
}
