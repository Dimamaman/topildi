import 'package:flutter/material.dart';

/// Decorative colours from the screen designs that are not in [TopildiColors]:
/// photo placeholders, skeletons and stylised map backgrounds.
@immutable
class TSurfaces {
  const TSurfaces._({
    required this.placeholders,
    required this.placeholderIcon,
    required this.skeleton,
    required this.skeletonSoft,
    required this.map,
    required this.road,
    required this.photoChip,
    required this.primaryTint,
    required this.park,
    required this.water,
    required this.separator,
    required this.hint,
  });

  final List<Color> placeholders;
  final Color placeholderIcon, skeleton, skeletonSoft, map, road, photoChip;

  /// Very light primary wash used behind the hidden-detail block.
  final Color primaryTint;
  final Color park, water;

  /// Hairline between rows of an inset settings group.
  final Color separator;

  /// Soft decorative accent: dashed hint arrows, sparkles.
  final Color hint;

  static const _light = TSurfaces._(
    placeholders: [Color(0xFFDCE4F2), Color(0xFFE1EBE5), Color(0xFFEDE3D6), Color(0xFFE4E1EE)],
    placeholderIcon: Color(0xFF5B6F94),
    skeleton: Color(0xFFE1E6EF),
    skeletonSoft: Color(0xFFEAEEF4),
    map: Color(0xFFE6EBF2),
    road: Color(0xFFFFFFFF),
    photoChip: Color(0x990F1420),
    primaryTint: Color(0xFFEDF2FD),
    park: Color(0xFFD4E7D9),
    water: Color(0xFFCDDDF3),
    separator: Color(0xFFC8CED9),
    hint: Color(0xFF8DB0FF),
  );

  // OLED dark (D2): neutral near-black surfaces, no green or purple tints.
  static const _dark = TSurfaces._(
    placeholders: [Color(0xFF17181B), Color(0xFF1B1C20), Color(0xFF1E1F23), Color(0xFF141518)],
    placeholderIcon: Color(0xFF5F6672),
    skeleton: Color(0xFF17181B),
    skeletonSoft: Color(0xFF111214),
    map: Color(0xFF0B0C0E),
    road: Color(0xFF17181B),
    photoChip: Color(0x99000000),
    primaryTint: Color(0xFF101A33),
    park: Color(0xFF14161A),
    water: Color(0xFF101A33),
    separator: Color(0xFF26282D),
    hint: Color(0xFF4D7FFF),
  );

  static TSurfaces of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  Color placeholder(int index) => placeholders[index % placeholders.length];
}

extension TSurfacesX on BuildContext {
  TSurfaces get ts => TSurfaces.of(this);
}
