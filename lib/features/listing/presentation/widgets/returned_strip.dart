import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/tr.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/returned_item.dart';
import '../category_ui.dart';

/// "Egasiga qaytdi": the proof row above the feed, in the shape of stories.
///
/// Nothing here is tappable at all. A returned listing has no page worth
/// reaching — no claim to send, no chat to join — so a tap would be a dead
/// end, and the row carries no control of its own either: it is small, it
/// narrows with the category chips and it leaves on its own once there is
/// too little to show, so a dismiss button would only be one more way to
/// lose it for good. For the same reason no item names anyone:
/// [ReturnedItem] carries no author at all.
///
/// Whether the row appears is not its own decision: the feed asks
/// `FeedState.showReturned` first.
class ReturnedStrip extends StatelessWidget {
  const ReturnedStrip({super.key, required this.items});

  final List<ReturnedItem> items;

  /// At most this many: the row is a glance, not a gallery.
  static const maxItems = 10;

  static const _itemWidth = 72.0, _avatar = 58.0, _ringPad = 3.0, _ring = 2.0;
  /// Top 6, not the design's 14: the pinned chip header already ends with
  /// 8 of its own, and the grid below adds 6 more to this bottom 10 — so the
  /// gaps the design asks for (14 above, 16 below) come out right on screen.
  static const _pad = EdgeInsets.fromLTRB(16, 6, 16, 10);

  /// Ring plus its padding on both sides.
  static double get _avatarExtent => _avatar + (_ringPad + _ring) * 2;

  /// The row's height at [scaler]: avatar, gap, title line, time line. Both
  /// text lines grow with the text size, so this cannot be a constant — at
  /// 130% a fixed height clips the time (see home_layout_test).
  static double _rowHeight(TextScaler scaler) =>
      _avatarExtent + 4 + scaler.scale(16) * 2 + 2;

  /// Items returned within the last seven days, for the header's count.
  int get _thisWeek {
    final since = DateTime.now().subtract(const Duration(days: 7));
    return items.where((i) => i.returnedAt.isAfter(since)).length;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final week = _thisWeek;
    final shown = items.take(maxItems).toList();
    return Semantics(
      container: true,
      label: tr('Egasiga qaytgan buyumlar'),
      child: Padding(
        padding: _pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Both labels share the row's free space evenly, so the title
            // keeps half to itself however long the count gets.
            Row(
              children: [
                Flexible(
                  child: Text(
                    tr('Egasiga qaytdi'),
                    style: text.labelLarge!.copyWith(fontSize: 15, height: 20 / 15).inter(FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Only once the week itself is worth mentioning.
                if (week >= 3) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '· ${tr('bu hafta {n}', {'n': week})}',
                      style: text.labelMedium?.copyWith(color: context.tc.onSurfaceMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: _rowHeight(MediaQuery.textScalerOf(context)),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                // Runs to the screen edge, so the last item is cut off and
                // the row reads as scrollable.
                padding: EdgeInsets.only(right: _pad.right),
                clipBehavior: Clip.none,
                itemCount: shown.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _Item(item: shown[i], pageColor: cs.surface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item, required this.pageColor});

  final ReturnedItem item;

  /// Behind the badge, so it cuts a notch out of the ring.
  final Color pageColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '${item.title}, ${item.district}, ${TDate.ago(item.returnedAt)}',
      excludeSemantics: true,
      child: SizedBox(
        width: ReturnedStrip._itemWidth,
        child: Column(
          children: [
            SizedBox(
              width: ReturnedStrip._avatarExtent,
              height: ReturnedStrip._avatarExtent,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.primary, width: ReturnedStrip._ring),
                    ),
                    padding: const EdgeInsets.all(ReturnedStrip._ringPad),
                    child: _Avatar(item: item),
                  ),
                  Positioned(right: -3, bottom: -3, child: _Badge(pageColor: pageColor)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: text.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              TDate.agoShort(item.returnedAt),
              style: text.bodySmall?.copyWith(color: tc.onSurfaceMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.item});

  final ReturnedItem item;

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    final photo = item.photo;
    return ClipOval(
      child: ColoredBox(
        color: tc.photoPlaceholder,
        child: photo == null
            ? Center(
                child: Icon(
                  item.category.icon,
                  size: 27,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : Image.network(
                photo,
                fit: BoxFit.cover,
                width: ReturnedStrip._avatar,
                height: ReturnedStrip._avatar,
                errorBuilder: (context, _, _) => Center(
                  child: Icon(
                    item.category.icon,
                    size: 27,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
    );
  }
}

/// The rosette tick. Its outer disc is the page colour so the badge sits in a
/// notch cut out of the ring; a white disc under the glyph keeps the tick
/// itself white in both themes.
class _Badge extends StatelessWidget {
  const _Badge({required this.pageColor});

  final Color pageColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: pageColor, shape: BoxShape.circle),
            child: const SizedBox.expand(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: SizedBox(width: 16, height: 16),
          ),
          Icon(Symbols.verified_rounded, size: 24, fill: 1, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }
}
