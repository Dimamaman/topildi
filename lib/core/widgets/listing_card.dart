import 'package:flutter/material.dart';

import '../theme/topildi_surfaces.dart';
import '../theme/topildi_theme.dart';
import 'photo_placeholder.dart';
import 'status_badge.dart';

/// Horizontal feed card: 104dp photo on the left, badges, title, meta line.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.title,
    required this.category,
    required this.meta,
    required this.isFound,
    required this.icon,
    this.tint = 0,
    this.imagePath,
    this.trailingBadge,
    this.onTap,
  });

  final String title, category, meta;
  final bool isFound;
  final IconData icon;
  final int tint;
  final String? imagePath;
  final Widget? trailingBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhotoPlaceholder(icon: icon, tint: tint, path: imagePath, width: TSize.cardPhoto, height: TSize.cardPhoto),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          TypeBadge(isFound: isFound, size: BadgeSize.small),
                          CategoryBadge(label: category, size: BadgeSize.small),
                          ?trailingBadge,
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium!.copyWith(height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall!.copyWith(fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton matching [ListingCard]'s layout.
class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    Widget bar(double? w, double h, Color c, {double factor = 1}) => FractionallySizedBox(
          widthFactor: w == null ? factor : null,
          alignment: Alignment.centerLeft,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(TRadius.xs)),
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: TSize.cardPhoto,
              height: TSize.cardPhoto,
              decoration: BoxDecoration(color: ts.skeleton, borderRadius: BorderRadius.circular(TRadius.sm)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(72, 18, ts.skeleton),
                    const SizedBox(height: 10),
                    bar(null, 14, ts.skeleton, factor: 0.9),
                    const SizedBox(height: 10),
                    bar(null, 12, ts.skeletonSoft, factor: 0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
