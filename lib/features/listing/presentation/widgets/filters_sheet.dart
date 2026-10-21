import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/glass_sheet.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/pull_down_menu.dart';
import '../../../../core/widgets/t_chip.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/regions.dart';
import '../category_ui.dart';
import '../cubit/filters_cubit.dart';

/// Opens the Filters sheet (iOS 26 floating glass sheet); returns the
/// applied filter, or null when closed without applying.
Future<ListingFilter?> showFiltersSheet(
  BuildContext context, {
  required ListingFilter filter,
  required ListingType type,
  required String search,
}) {
  return showGlassSheet<ListingFilter>(
    context,
    label: 'Filtrlar',
    builder: (_) => BlocProvider(
      create: (_) => getIt<FiltersCubit>()..start(filter: filter, type: type, search: search),
      child: const _FiltersSheet(),
    ),
  );
}

const _allDistricts = 'Barcha tumanlar';

class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FiltersCubit, FiltersState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(canReset: !state.filter.isDefault),
          Expanded(
            child: SingleChildScrollView(
              // Clamping, so pulling down at the top drags the sheet instead.
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionTitle('Kategoriya'),
                  _Categories(selected: state.filter.categories),
                  const _SectionTitle('Hudud'),
                  _Region(filter: state.filter),
                  const _SectionTitle('Sana'),
                  _Dates(filter: state.filter),
                ],
              ),
            ),
          ),
          _ShowButton(count: state.count, filter: state.filter),
        ],
      ),
    );
  }
}

/// Yopish · "Filtrlar" · Tozalash.
class _Header extends StatelessWidget {
  const _Header({required this.canReset});

  final bool canReset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final g = context.glass;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Filtrlar',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontSize: 17, height: 22 / 17).inter(FontWeight.w600),
              ),
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Yopish',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox.square(
                        dimension: 44,
                        child: GlassSurface(
                          color: g.control,
                          child: Icon(Symbols.close_rounded, size: 22, color: cs.onSurface),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    enabled: canReset,
                    label: 'Tozalash',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: canReset ? context.read<FiltersCubit>().reset : null,
                      behavior: HitTestBehavior.opaque,
                      child: Opacity(
                        opacity: canReset ? 1 : 0.4,
                        child: SizedBox(
                          height: 44,
                          child: GlassSurface(
                            color: g.control,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                'Tozalash',
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(fontSize: 15, height: 20 / 15, color: cs.primary)
                                    .inter(FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "KATEGORIYA"-style caption above a group.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 13,
            height: 18 / 13,
            letterSpacing: 0.2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// White rounded group (radius 26).
class _Group extends StatelessWidget {
  const _Group({required this.padding, required this.child});

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(26),
      ),
      child: child,
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.selected});

  final Set<ItemCategory> selected;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FiltersCubit>();
    return _Group(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // Chips have a 44dp hit area around the 36dp pill: no extra run spacing.
      child: Wrap(
        spacing: 8,
        children: [
          for (final c in ItemCategory.values)
            TChip(label: c.label, icon: c.icon, selected: selected.contains(c), onTap: () => cubit.toggleCategory(c)),
        ],
      ),
    );
  }
}

class _Region extends StatelessWidget {
  const _Region({required this.filter});

  final ListingFilter filter;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FiltersCubit>();
    final districts = Regions.districtsOf(filter.city);
    return _Group(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _RegionRow(
            icon: Symbols.location_city_rounded,
            label: 'Shahar / viloyat',
            value: filter.city,
            divider: true,
            onPick: (anchor, drag) async {
              final v = await showPullDownMenu(
                context,
                anchor: anchor,
                label: 'Shahar / viloyat',
                drag: drag,
                items: [for (final c in Regions.cities) (c, c)],
                current: filter.city,
              );
              // Changing the city resets the district to "Barcha tumanlar".
              if (v != null && v != filter.city) cubit.setCity(v);
            },
          ),
          _RegionRow(
            icon: Symbols.map_rounded,
            label: 'Tuman',
            value: filter.district ?? _allDistricts,
            onPick: districts.isEmpty
                ? null
                : (anchor, drag) async {
                    final v = await showPullDownMenu(
                      context,
                      anchor: anchor,
                      label: 'Tuman',
                      drag: drag,
                      dividersAfter: const {0},
                      items: [(_allDistricts, _allDistricts), for (final d in districts) (d, d)],
                      current: filter.district ?? _allDistricts,
                    );
                    if (v != null) cubit.setDistrict(v == _allDistricts ? null : v);
                  },
          ),
        ],
      ),
    );
  }
}

/// Icon · label … value capsule ⇕ — opens the glass pull-down menu under
/// the row. Tap to open, or press, slide onto an item and release.
class _RegionRow extends StatefulWidget {
  const _RegionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPick,
    this.divider = false,
  });

  final IconData icon;
  final String label, value;
  final Future<void> Function(BuildContext anchor, PullDownDrag? drag)? onPick;
  final bool divider;

  @override
  State<_RegionRow> createState() => _RegionRowState();
}

class _RegionRowState extends State<_RegionRow> {
  bool _open = false;
  PullDownDrag? _drag;

  Future<void> _show(BuildContext anchor, {PullDownDrag? drag}) async {
    if (_open) return;
    setState(() => _open = true);
    await widget.onPick!(anchor, drag);
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final g = context.glass;
    final style = Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 15, height: 20 / 15);
    final enabled = widget.onPick != null;
    return Semantics(
      button: true,
      enabled: enabled,
      expanded: _open,
      label: '${widget.label}, ${widget.value}',
      excludeSemantics: true,
      child: Builder(
        builder: (anchor) => GestureDetector(
          onTap: enabled ? () => _show(anchor) : null,
          onLongPressStart: enabled
              ? (d) {
                  _drag = PullDownDrag()..move(d.globalPosition);
                  _show(anchor, drag: _drag);
                }
              : null,
          onLongPressMoveUpdate: (d) => _drag?.move(d.globalPosition),
          onLongPressEnd: (_) {
            _drag?.release();
            _drag = null;
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Icon(widget.icon, size: 22, color: enabled ? cs.primary : cs.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                    decoration: widget.divider
                        ? BoxDecoration(
                            border: Border(bottom: BorderSide(color: context.ts.separator, width: 0.5)),
                          )
                        : null,
                    // Label at its own width (at most 55%), the value capsule takes the rest, right-aligned.
                    child: LayoutBuilder(
                      builder: (context, c) => Row(
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: c.maxWidth * 0.55),
                            child: Text(widget.label, style: style.copyWith(color: cs.onSurface)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                constraints: const BoxConstraints(minHeight: 32),
                                padding: const EdgeInsets.only(left: 12, right: 6),
                                decoration: BoxDecoration(
                                  color: _open ? g.menuSourceOpen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: _open
                                            ? style.copyWith(color: cs.onSurface).inter(FontWeight.w600)
                                            : style.copyWith(color: enabled ? cs.onSurfaceVariant : cs.outline),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(Symbols.unfold_more_rounded, size: 18, color: cs.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dates extends StatelessWidget {
  const _Dates({required this.filter});

  final ListingFilter filter;

  static const _periods = [DatePeriod.today, DatePeriod.week, DatePeriod.month, DatePeriod.custom];
  static const _labels = ['Bugun', '7 kun', '30 kun', 'Tanlash'];

  Future<void> _pickRange(BuildContext context) async {
    final cubit = context.read<FiltersCubit>();
    final now = DateTime.now();
    final initial = DateTimeRange(start: filter.start(now), end: filter.end(now).subtract(const Duration(days: 1)));
    final first = now.subtract(const Duration(days: 365));
    final picked = Theme.of(context).platform == TargetPlatform.iOS
        ? _cupertinoRange(context, initial: initial, first: first, last: now)
        : showDateRangePicker(context: context, firstDate: first, lastDate: now, initialDateRange: initial);
    final range = await picked;
    if (range != null) cubit.setRange(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final last = filter.end(now).subtract(const Duration(days: 1));
    final range = '${TDate.dayMonth(filter.start(now))} — ${TDate.dayMonth(last)}, ${last.year}';
    return _Group(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TCapsuleSegmented(
            height: 38,
            fontSize: 14,
            inactiveColor: cs.onSurface,
            selected: _periods.indexOf(filter.period),
            segments: [for (final l in _labels) (label: l, color: null)],
            onChanged: (i) {
              final p = _periods[i];
              if (p == DatePeriod.custom) {
                _pickRange(context);
              } else {
                context.read<FiltersCubit>().setPeriod(p);
              }
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Symbols.calendar_month_rounded, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    range,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(fontSize: 14, height: 19 / 14, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS range picker: "Dan" / "Gacha" switch over a [CupertinoDatePicker].
Future<DateTimeRange?> _cupertinoRange(
  BuildContext context, {
  required DateTimeRange initial,
  required DateTime first,
  required DateTime last,
}) {
  var start = initial.start, end = initial.end;
  var editingEnd = false;
  return showCupertinoModalPopup<DateTimeRange>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return StatefulBuilder(
        builder: (ctx, setState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  child: Row(
                    children: [
                      CupertinoButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor qilish')),
                      const Spacer(),
                      CupertinoButton(
                        onPressed: () => Navigator.pop(ctx, DateTimeRange(start: start, end: end)),
                        child: const Text('Tayyor', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TCapsuleSegmented(
                    height: 38,
                    fontSize: 14,
                    inactiveColor: cs.onSurface,
                    selected: editingEnd ? 1 : 0,
                    segments: [
                      (label: 'Dan: ${TDate.dayMonth(start)}', color: null),
                      (label: 'Gacha: ${TDate.dayMonth(end)}', color: null),
                    ],
                    onChanged: (i) => setState(() => editingEnd = i == 1),
                  ),
                ),
                SizedBox(
                  height: 216,
                  child: CupertinoDatePicker(
                    key: ValueKey(editingEnd),
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: editingEnd ? end : start,
                    minimumDate: editingEnd ? start : first,
                    maximumDate: editingEnd ? last : end,
                    onDateTimeChanged: (d) => setState(() => editingEnd ? end = d : start = d),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// "N ta natijani koʻrsatish" — applies the filter and closes the sheet.
class _ShowButton extends StatelessWidget {
  const _ShowButton({required this.count, required this.filter});

  final int? count;
  final ListingFilter filter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final none = count == 0;
    final style = Theme.of(
      context,
    ).textTheme.bodyLarge!.copyWith(fontSize: 17, height: 22 / 17, color: cs.onPrimary).inter(FontWeight.w600);
    final Widget label = switch (count) {
      null => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(radius: 8, color: cs.onPrimary),
          const SizedBox(width: 6),
          Flexible(child: Text('ta natijani koʻrsatish', style: style, maxLines: 1)),
        ],
      ),
      0 => Text('Natija topilmadi', style: style, maxLines: 1),
      final n => Text('$n ta natijani koʻrsatish', style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
    };
    return Semantics(
      button: true,
      enabled: !none,
      child: GestureDetector(
        onTap: none ? null : () => Navigator.of(context).pop(filter),
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: none ? 0.5 : 1,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(999)),
            alignment: Alignment.center,
            child: label,
          ),
        ),
      ),
    );
  }
}
