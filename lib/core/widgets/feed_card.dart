import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/topildi_surfaces.dart';
import '../theme/topildi_theme.dart';
import 'glass_surface.dart';
import 'photo_placeholder.dart';
import '../theme/t_text.dart';

/// Feed card (iOS 26 Lenta): full-width 168dp photo with glass tags for the
/// type and time, then title, "Kategoriya · Hudud" and a chevron.
class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.title,
    required this.meta,
    required this.time,
    required this.isFound,
    required this.icon,
    this.tint = 0,
    this.imagePath,
    this.onTap,
  });

  static const radius = 28.0;
  static const photoHeight = 168.0;

  final String title, meta, time;
  final bool isFound;
  final IconData icon;
  final int tint;
  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final type = isFound ? 'Topilgan' : 'Yoʻqolgan';
    final typeColor = isFound ? tc.found : tc.lost;
    return Semantics(
      button: true,
      label: '$type. $title. $meta. $time',
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
                      iconSize: 64,
                      radius: 0,
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          _GlassTag(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(type, style: _tagStyle(context, FontWeight.w600, typeColor)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _GlassTag(
                                child: Text(
                                  time,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _tagStyle(context, FontWeight.w500, cs.onSurface),
                                ),
                              ),
                            ),
                          ),
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

  static TextStyle _tagStyle(BuildContext context, FontWeight w, Color c) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 13, height: 18 / 13, color: c).inter(w);
}

/// 30dp glass capsule laid over the photo.
class _GlassTag extends StatelessWidget {
  const _GlassTag({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      color: context.glass.tag,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Align(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}

/// Skeleton matching [FeedCard]'s layout.
class FeedCardSkeleton extends StatelessWidget {
  const FeedCardSkeleton({super.key});

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
          Container(height: FeedCard.photoHeight, color: ts.skeleton),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [bar(0.7, 18, ts.skeleton), const SizedBox(height: 8), bar(0.45, 13, ts.skeletonSoft)],
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
