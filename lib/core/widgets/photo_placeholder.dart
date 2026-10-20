import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/topildi_surfaces.dart';
import '../theme/topildi_theme.dart';

/// Listing photo: the local image at [path] when available, otherwise a
/// tinted box with the item icon.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({
    super.key,
    required this.icon,
    this.tint = 0,
    this.width,
    this.height,
    this.iconSize = 40,
    this.radius = TRadius.sm,
    this.path,
  });

  final IconData icon;
  final int tint;
  final double? width, height;
  final double iconSize, radius;
  final String? path;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: ts.placeholder(tint), borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: ts.placeholderIcon, weight: 300),
    );
    final p = path;
    if (p == null || !p.startsWith('/')) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(
        File(p),
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: width == null || width!.isInfinite ? null : (width! * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
