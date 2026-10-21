import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_chip.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/regions.dart';
import '../category_ui.dart';
import '../cubit/filters_cubit.dart';

/// Opens the Filters sheet; returns the applied filter or null if dismissed.
Future<ListingFilter?> showFiltersSheet(
  BuildContext context, {
  required ListingFilter filter,
  required ListingType type,
  required String search,
}) {
  return showModalBottomSheet<ListingFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider(
      create: (_) => getIt<FiltersCubit>()..start(filter: filter, type: type, search: search),
      child: const _FiltersSheet(),
    ),
  );
}

class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet();

  Future<String?> _pick(BuildContext context, String title, List<String> options, String? current) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(TSpace.screen, 0, TSpace.screen, TSpace.xs),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final o in options)
              ListTile(
                minTileHeight: TSize.tapTarget,
                title: Text(o),
                trailing: o == current ? const Icon(Symbols.check_rounded) : null,
                onTap: () => Navigator.pop(ctx, o),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<FiltersCubit>();
    const allDistricts = 'Barcha tumanlar';

    return BlocBuilder<FiltersCubit, FiltersState>(
      builder: (context, state) {
        final f = state.filter;
        final now = DateTime.now();
        final districts = Regions.districtsOf(f.city);
        final range = '${TDate.dayMonth(f.start(now))} — ${TDate.dayMonth(f.end(now).subtract(const Duration(days: 1)))}, '
            '${f.end(now).subtract(const Duration(days: 1)).year}';

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TSpace.screen),
                child: Row(
                  children: [
                    const Expanded(child: Text('Filtrlar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                    TextButton(onPressed: cubit.reset, child: const Text('Tozalash', style: TextStyle(fontSize: 15))),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(TSpace.screen, 4, TSpace.screen, TSpace.lg),
                  children: [
                    const _Label('Kategoriya'),
                    Wrap(
                      spacing: TSpace.xs,
                      children: [
                        for (final c in ItemCategory.values)
                          TChip(
                            label: c.label,
                            icon: c.icon,
                            selected: f.categories.contains(c),
                            showCheck: true,
                            onTap: () => cubit.toggleCategory(c),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _Label('Hudud'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _SelectField(
                            label: 'Shahar / viloyat',
                            value: f.city,
                            onTap: () async {
                              final v = await _pick(context, 'Shahar / viloyat', Regions.cities, f.city);
                              if (v != null) cubit.setCity(v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SelectField(
                            label: 'Tuman',
                            value: f.district ?? allDistricts,
                            onTap: districts.isEmpty
                                ? null
                                : () async {
                                    final v = await _pick(context, 'Tuman', [allDistricts, ...districts], f.district ?? allDistricts);
                                    if (v != null) cubit.setDistrict(v == allDistricts ? null : v);
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _Label('Sana'),
                    const SizedBox(height: 6),
                    _PeriodSegments(
                      period: f.period,
                      onChanged: (p) async {
                        if (p != DatePeriod.custom) return cubit.setPeriod(p);
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: now.subtract(const Duration(days: 365)),
                          lastDate: now,
                          initialDateRange: DateTimeRange(start: f.start(now), end: now),
                        );
                        if (picked != null) cubit.setRange(picked.start, picked.end);
                      },
                    ),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(minHeight: TSize.input),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(TRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(Symbols.calendar_month_rounded, size: 20, color: cs.secondary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(range, style: TextStyle(fontSize: 15, color: cs.secondary))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant))),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: TSpace.sm),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(TSpace.screen, TSpace.sm, TSpace.screen, TSpace.sm),
                    child: TButton.primary(
                      label: state.count == null
                          ? 'Natijalarni koʻrsatish'
                          : state.count == 0
                              ? 'Natija topilmadi'
                              : '${state.count} ta natijani koʻrsatish',
                      onPressed: state.count == 0 ? null : () => Navigator.pop(context, f),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );
}

class _SelectField extends StatelessWidget {
  const _SelectField({required this.label, required this.value, required this.onTap});

  final String label, value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TRadius.md), side: BorderSide(color: cs.outline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TSize.input),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      Text(value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600, color: onTap == null ? cs.onSurfaceVariant : null)),
                    ],
                  ),
                ),
                Icon(Symbols.expand_more_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodSegments extends StatelessWidget {
  const _PeriodSegments({required this.period, required this.onChanged});

  final DatePeriod period;
  final ValueChanged<DatePeriod> onChanged;

  static const _labels = {
    DatePeriod.today: 'Bugun',
    DatePeriod.week: '7 kun',
    DatePeriod.month: '30 kun',
    DatePeriod.custom: 'Tanlash',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TRadius.md),
        border: Border.all(color: cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, e) in _labels.entries.indexed) ...[
              if (i > 0) VerticalDivider(width: 1, color: cs.outlineVariant),
              Expanded(
                child: Semantics(
                  selected: e.key == period,
                  button: true,
                  child: Material(
                    color: e.key == period ? cs.primaryContainer : cs.surfaceContainerLowest,
                    child: InkWell(
                      onTap: () => onChanged(e.key),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: TSize.tapTarget),
                        child: Center(
                          child: Text(
                            e.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: e.key == period ? cs.onPrimaryContainer : cs.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
