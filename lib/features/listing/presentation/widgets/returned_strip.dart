import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../domain/entities/returned_item.dart';
import '../category_ui.dart';

/// "Egasiga qaytdi": the proof strip above the feed.
///
/// Not a list of listings — a wall of finished stories. Nothing here opens:
/// a returned item has no page worth reaching, no claim to send and no chat
/// to join, so a tap would only lead to a dead end. For the same reason no
/// card names anyone ([ReturnedItem] carries no author at all).
///
/// Whether the strip appears is not its own decision: the feed asks
/// `FeedState.showReturned` first, which keeps it off screen entirely while
/// there is too little to show.
class ReturnedStrip extends StatelessWidget {
  const ReturnedStrip({super.key, required this.items});

  final List<ReturnedItem> items;

  static const _cardWidth = 112.0, _photoHeight = 78.0;
  static const _pad = EdgeInsets.fromLTRB(16, 12, 16, 14);

  /// Text block under the photo: title line, meta line and the gap above
  /// them. Both grow with the text size, so the row cannot be a fixed
  /// height — at 130% it would clip the district (see home_layout_test).
  static const _gap = 6.0, _titleLine = 20.0, _metaLine = 16.0;

  static double _rowHeight(TextScaler scaler) =>
      _photoHeight + _gap + scaler.scale(_titleLine) + scaler.scale(_metaLine) + 2;

  /// Items returned within the last seven days, for the header's count.
  int get _thisWeek {
    final since = DateTime.now().subtract(const Duration(days: 7));
    return items.where((i) => i.returnedAt.isAfter(since)).length;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    final week = _thisWeek;
    return Semantics(
      container: true,
      label: tr('Egasiga qaytgan buyumlar'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          border: Border.symmetric(horizontal: BorderSide(color: cs.outlineVariant)),
        ),
        child: Padding(
          padding: _pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Symbols.check_circle_rounded, size: 18, color: tc.success),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      tr('Egasiga qaytdi'),
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Only once the week itself is worth mentioning.
                  if (week >= 3) ...[
                    const SizedBox(width: 8),
                    _WeekCount(count: week),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: _rowHeight(MediaQuery.textScalerOf(context)),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _Card(item: items[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekCount extends StatelessWidget {
  const _WeekCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: tc.successContainer, borderRadius: BorderRadius.circular(TRadius.full)),
      child: Text(
        tr('bu hafta {n}', {'n': count}),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tc.success),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.item});

  final ReturnedItem item;

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: ReturnedStrip._cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              PhotoPlaceholder(
                icon: item.category.icon,
                path: item.photo,
                width: ReturnedStrip._cardWidth,
                height: ReturnedStrip._photoHeight,
                iconSize: 26,
                radius: TRadius.md,
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(color: tc.success, shape: BoxShape.circle),
                  child: Icon(Symbols.check_rounded, size: 13, color: Theme.of(context).colorScheme.onPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: ReturnedStrip._gap),
          Text(item.title, style: text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            '${item.district} · ${TDate.ago(item.returnedAt)}',
            style: text.bodySmall?.copyWith(color: tc.onSurfaceMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
