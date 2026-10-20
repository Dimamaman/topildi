import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/topildi_theme.dart';

/// 36dp filter chip; the hit area is padded to 48dp.
class TChip extends StatelessWidget {
  const TChip({super.key, required this.label, required this.selected, required this.onTap, this.showCheck = false});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TSize.tapTarget),
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? cs.primaryContainer : cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(TRadius.sm),
                border: Border.all(color: selected ? cs.primaryContainer : cs.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showCheck && selected) ...[
                    Icon(Symbols.check_rounded, size: 16, color: fg, weight: 600),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling single-select chip row.
class TChipRow extends StatelessWidget {
  const TChipRow({super.key, required this.labels, required this.selected, required this.onSelected, this.padding});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: TSpace.screen),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: TSpace.xs),
            TChip(label: labels[i], selected: i == selected, onTap: () => onSelected(i)),
          ],
        ],
      ),
    );
  }
}

/// Found / Lost segmented control, iOS style: a rounded track with a
/// sliding thumb. Tap or drag across to switch. Each segment shows a
/// coloured dot *and* text, so the choice never relies on colour alone.
class TTypeTabs extends StatelessWidget {
  const TTypeTabs({super.key, required this.isFound, required this.onChanged});

  final bool isFound;
  final ValueChanged<bool> onChanged;

  static const _height = TSize.tapTarget;
  static const _inset = 4.0;
  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final track = dark ? cs.surface : cs.surfaceContainerHigh;
    final thumb = dark ? cs.surfaceContainerHighest : cs.surfaceContainerLowest;

    Widget segment(bool found, String label, Color color) {
      final active = found == isFound;
      return Expanded(
        child: Semantics(
          selected: active,
          button: true,
          inMutuallyExclusiveGroup: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(found),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: _duration,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                        color: active ? color : cs.onSurfaceVariant,
                      ),
                      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) => GestureDetector(
        // Drag across the track to switch, like UISegmentedControl.
        onHorizontalDragUpdate: (d) {
          final toFound = d.localPosition.dx < c.maxWidth / 2;
          if (toFound != isFound) onChanged(toFound);
        },
        child: Container(
          height: _height,
          padding: const EdgeInsets.all(_inset),
          decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(TRadius.md + _inset)),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: _duration,
                curve: Curves.easeOutCubic,
                alignment: isFound ? Alignment.centerLeft : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: thumb,
                      borderRadius: BorderRadius.circular(TRadius.md),
                      boxShadow: dark
                          ? null
                          : [
                              BoxShadow(color: cs.scrim.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 2)),
                              BoxShadow(color: cs.scrim.withValues(alpha: 0.04), blurRadius: 1, offset: const Offset(0, 1)),
                            ],
                    ),
                  ),
                ),
              ),
              Row(children: [segment(true, 'Topilgan', tc.found), segment(false, 'Yoʻqolgan', tc.lost)]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small two-option segmented control (Roʻyxat / Xarita).
class TSegmented extends StatelessWidget {
  const TSegmented({super.key, required this.items, required this.selected, required this.onChanged});

  final List<(IconData, String)> items;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            Flexible(
              child: Semantics(
                selected: i == selected,
                button: true,
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: i == selected ? cs.primaryContainer : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i].$1, size: 16, color: i == selected ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            items[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                              color: i == selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
