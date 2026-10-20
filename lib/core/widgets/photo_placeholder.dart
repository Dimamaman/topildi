import 'package:flutter/material.dart';

import '../theme/topildi_surfaces.dart';
import '../theme/topildi_theme.dart';

/// Tinted box with an item icon, used until real photos are available.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({
    super.key,
    required this.icon,
    this.tint = 0,
    this.width,
    this.height,
    this.iconSize = 40,
    this.radius = TRadius.sm,
  });

  final IconData icon;
  final int tint;
  final double? width, height;
  final double iconSize, radius;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: ts.placeholder(tint), borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: ts.placeholderIcon, weight: 300),
    );
  }
}
