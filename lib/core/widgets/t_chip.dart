import 'package:flutter/material.dart';

import '../theme/topildi_theme.dart';
import '../theme/t_text.dart';
import 'glass_surface.dart';
import '../l10n/tr.dart';

/// Capsule filter chip (36dp, hit area padded to 44dp) with an optional
/// leading icon. Selected: filled `primary`; unselected: quiet grey fill,
/// `on-surface` text, no border.
class TChip extends StatelessWidget {
  const TChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimary : cs.onSurface;
    final leading = icon;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              // Bounded, so a very long label (large text) ellipsizes instead of overflowing.
              constraints: BoxConstraints(minHeight: 36, maxWidth: MediaQuery.sizeOf(context).width - 64),
              padding: EdgeInsets.only(left: leading == null ? 16 : 10, right: leading == null ? 16 : 12, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: selected ? cs.primary : context.glass.quiet,
                borderRadius: BorderRadius.circular(TRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[Icon(leading, size: 18, color: fg), const SizedBox(width: 6)],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium!
                          .copyWith(fontSize: 14, height: 20 / 14, color: fg)
                          .inter(selected ? FontWeight.w600 : FontWeight.w500),
                    ),
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

/// Horizontally scrolling single-select chip row. [icons] (optional) gives a
/// leading icon per label; null entries have none.
class TChipRow extends StatelessWidget {
  const TChipRow({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.icons,
    this.padding,
  });

  final List<String> labels;
  final List<IconData?>? icons;
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
            TChip(
              label: labels[i],
              icon: icons != null && i < icons!.length ? icons![i] : null,
              selected: i == selected,
              onTap: () => onSelected(i),
            ),
          ],
        ],
      ),
    );
  }
}

/// Found / Lost segmented control: [TCapsuleSegmented] where each segment
/// shows a coloured dot *and* text, so the choice never relies on colour alone.
class TTypeTabs extends StatelessWidget {
  const TTypeTabs({super.key, required this.isFound, required this.onChanged});

  final bool isFound;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return TCapsuleSegmented(
      selected: isFound ? 0 : 1,
      onChanged: (i) => onChanged(i == 0),
      segments: [
        (label: tr('Topilgan'), color: tc.found),
        (label: tr('Yoʻqolgan'), color: tc.lost),
      ],
    );
  }
}

/// Segmented control, iOS 26 style: a capsule track with a sliding glass
/// thumb and equal segments. Tap or drag across to switch. A segment with a
/// `color` gets a dot in that colour and, when selected, coloured text;
/// otherwise the selected text is `on-surface`.
class TCapsuleSegmented extends StatelessWidget {
  const TCapsuleSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 44,
    this.fontSize = 15,
    this.inactiveColor,
  }) : assert(segments.length >= 2);

  final List<({String label, Color? color})> segments;
  final int selected;
  final ValueChanged<int> onChanged;
  final double height, fontSize;

  /// Unselected text; defaults to `secondary`.
  final Color? inactiveColor;

  static const _inset = 3.0;
  static const _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final g = context.glass;

    Widget segment(int i) {
      final active = i == selected;
      final color = segments[i].color;
      return Expanded(
        child: Semantics(
          selected: active,
          button: true,
          inMutuallyExclusiveGroup: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (color != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: _duration,
                      style: Theme.of(context).textTheme.bodyMedium!
                          .copyWith(
                            fontSize: fontSize,
                            height: 20 / fontSize,
                            color: active ? (color ?? cs.onSurface) : (inactiveColor ?? cs.secondary),
                          )
                          .inter(active ? FontWeight.w600 : FontWeight.w500),
                      child: Text(segments[i].label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
          final n = segments.length;
          final to = (d.localPosition.dx / c.maxWidth * n).floor().clamp(0, n - 1);
          if (to != selected) onChanged(to);
        },
        child: Container(
          height: height,
          padding: const EdgeInsets.all(_inset),
          decoration: BoxDecoration(color: g.quiet, borderRadius: BorderRadius.circular(TRadius.full)),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: _duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment(-1 + 2 * selected / (segments.length - 1), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / segments.length,
                  heightFactor: 1,
                  child: GlassSurface(color: g.thumb, child: const SizedBox.expand()),
                ),
              ),
              Row(children: [for (var i = 0; i < segments.length; i++) segment(i)]),
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
