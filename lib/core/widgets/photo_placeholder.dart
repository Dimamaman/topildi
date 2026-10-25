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
    final provider = photoProvider(path);
    if (provider == null) return fallback;
    final cacheWidth = width == null || width!.isInfinite ? null : (width! * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image(
        image: cacheWidth == null ? provider : ResizeImage(provider, width: cacheWidth, policy: ResizeImagePolicy.fit),
        width: width,
        height: height,
        fit: BoxFit.cover,
        // Network photos: the tinted placeholder until the bytes arrive.
        frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : fallback,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// Image for a stored photo: a local file path (fresh picks, tests) or a
/// download URL (Firebase Storage). Null when there is nothing to show.
ImageProvider? photoProvider(String? path) {
  if (path == null) return null;
  if (path.startsWith('/')) return FileImage(File(path));
  if (path.startsWith('http')) return NetworkImage(path);
  return null;
}
