import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/t_text.dart';
import '../theme/topildi_surfaces.dart';
import '../theme/topildi_theme.dart';
import 'glass_surface.dart';
import 'photo_placeholder.dart';
import '../l10n/tr.dart';

/// Listing card, iOS 26 style (Lenta, Mening eʼlonlarim): full-width photo
/// with two glass tags on top, then title, a meta line and a chevron.
class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.title,
    required this.meta,
    required this.icon,
    required this.leadingTag,
    required this.trailingTag,
    required this.semanticLabel,
    this.tint = 0,
    this.imagePath,
    this.photoHeight = 168,
    this.iconSize = 64,
    this.onTap,
  });

  static const radius = 28.0;

  final String title, meta;
  final IconData icon;

  /// Tags over the photo, top-left and top-right (see [GlassTag]).
  final Widget leadingTag, trailingTag;

  /// Whole-card label for screen readers (tags are excluded).
  final String semanticLabel;
  final int tint;
  final String? imagePath;
  final double photoHeight, iconSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(radius)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: photoHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PhotoPlaceholder(
                      icon: icon,
                      tint: tint,
                      path: imagePath,
                      width: double.infinity,
                      height: photoHeight,
                      iconSize: iconSize,
                      radius: 0,
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      // Each tag shrinks to fit; free space goes between them.
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Padding(padding: const EdgeInsets.only(right: 8), child: leadingTag),
                          ),
                          Flexible(child: trailingTag),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(fontSize: 18, height: 24 / 18, letterSpacing: -0.2)
                                .inter(FontWeight.w700),
                          ),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.copyWith(fontSize: 14, height: 19 / 14, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: context.glass.quiet, shape: BoxShape.circle),
                      child: Icon(Symbols.chevron_right_rounded, size: 20, color: cs.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 30dp glass capsule laid over a listing photo.
class GlassTag extends StatelessWidget {
  const GlassTag({
    super.key,
    required this.label,
    required this.color,
    this.fill,
    this.icon,
    this.dot = false,
    this.weight = FontWeight.w600,
  });

  /// "Topilgan" / "Yoʻqolgan" tag: coloured dot + text, never colour alone.
  factory GlassTag.type(BuildContext context, {required bool isFound}) {
    final tc = context.tc;
    return GlassTag(label: isFound ? tr('Topilgan') : tr('Yoʻqolgan'), color: isFound ? tc.found : tc.lost, dot: true);
  }

  /// Neutral text tag, e.g. the time "Bugun, 09:40".
  factory GlassTag.text(BuildContext context, String label) =>
      GlassTag(label: label, color: Theme.of(context).colorScheme.onSurface, weight: FontWeight.w500);

  final String label;
  final Color color;

  /// Glass fill; defaults to [TGlass.tag].
  final Color? fill;
  final IconData? icon;
  final bool dot;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      color: fill ?? context.glass.tag,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              if (icon != null) ...[Icon(icon, size: 16, fill: 1, color: color), const SizedBox(width: 6)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(fontSize: 13, height: 18 / 13, color: color).inter(weight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton matching [FeedCard]'s layout.
class FeedCardSkeleton extends StatelessWidget {
  const FeedCardSkeleton({super.key, this.photoHeight = 168});

  final double photoHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = context.ts;
    Widget bar(double factor, double h, Color c) => FractionallySizedBox(
      widthFactor: factor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: h,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(TRadius.xs)),
      ),
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(FeedCard.radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: photoHeight, color: ts.skeleton),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(0.7, 18, ts.skeleton),
                      const SizedBox(height: 8),
                      bar(0.45, 13, ts.skeletonSoft),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: ts.skeletonSoft, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact listing card for the two-column Lenta grid: photo with the type
/// tag, then title (up to two lines), "category · area" and the time.
/// Grid cells are a fixed height, see [extent].
class FeedGridCard extends StatelessWidget {
  const FeedGridCard({
    super.key,
    required this.title,
    required this.meta,
    required this.time,
    required this.icon,
    required this.tag,
    required this.semanticLabel,
    this.tint = 0,
    this.imagePath,
    this.onTap,
  });

  static const radius = 22.0;

  /// Photo height as a share of the card width.
  static const photoRatio = 0.9;

  static const _pad = EdgeInsets.fromLTRB(12, 10, 12, 12);
  static const _titleLine = 20.0, _metaLine = 17.0, _timeLine = 16.0;

  /// Cell height for [width]: photo plus the text block at the current text
  /// size. The title always reserves two lines so a row's cards line up.
  static double extent(double width, TextScaler scaler) =>
      width * photoRatio +
      _pad.vertical +
      scaler.scale(_titleLine * 2) +
      4 +
      scaler.scale(_metaLine) +
      2 +
      scaler.scale(_timeLine) +
      2; // Rounding slack for font metrics.

  final String title, meta, time;
  final IconData icon;

  /// Tag over the photo, top-left (see [GlassTag.type]).
  final Widget tag;

  /// Whole-card label for screen readers (the tag is excluded).
  final String semanticLabel;
  final int tint;
  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(radius)),
          child: LayoutBuilder(
            builder: (context, c) {
              final photo = c.maxWidth * photoRatio;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: photo,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PhotoPlaceholder(
                          icon: icon,
                          tint: tint,
                          path: imagePath,
                          width: c.maxWidth,
                          height: photo,
                          iconSize: 44,
                          radius: 0,
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          right: 10,
                          child: Align(alignment: Alignment.centerLeft, child: tag),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: _pad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium!
                              .copyWith(fontSize: 15, height: _titleLine / 15, letterSpacing: -0.1)
                              .inter(FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall!
                              .copyWith(fontSize: 13, height: _metaLine / 13, color: cs.onSurfaceVariant)
                              .inter(FontWeight.w400),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          time,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall!
                              .copyWith(fontSize: 12, height: _timeLine / 12, color: cs.onSurfaceVariant)
                              .inter(FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Skeleton matching [FeedGridCard]'s layout.
class FeedGridCardSkeleton extends StatelessWidget {
  const FeedGridCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = context.ts;
    Widget bar(double factor, double h, Color c) => FractionallySizedBox(
      widthFactor: factor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: h,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(TRadius.xs)),
      ),
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(FeedGridCard.radius),
      ),
      child: LayoutBuilder(
        builder: (context, c) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: c.maxWidth * FeedGridCard.photoRatio, color: ts.skeleton),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(0.85, 14, ts.skeleton),
                  const SizedBox(height: 8),
                  bar(0.6, 12, ts.skeletonSoft),
                  const SizedBox(height: 6),
                  bar(0.4, 11, ts.skeletonSoft),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
