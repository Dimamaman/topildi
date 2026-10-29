import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/pull_down_menu.dart';
import '../../../listing/domain/entities/regions.dart';
import '../../domain/entities/create_draft.dart';
import '../cubit/create_flow_cubit.dart';
import '../pages/create_flow_page.dart';
import 'create_ui.dart';
import '../../../../core/l10n/tr.dart';

/// Step 3: region and district (with "Aniqlash"), an optional landmark and
/// when it happened. No map: the listing is placed by district.
class CreateLocationStep extends StatefulWidget {
  const CreateLocationStep({super.key, required this.controller, required this.top});

  final ScrollController controller;

  /// Room above the form for the preview card.
  final double top;

  @override
  State<CreateLocationStep> createState() => _CreateLocationStepState();
}

class _CreateLocationStepState extends State<CreateLocationStep> {
  late final CreateFlowCubit _cubit = context.read<CreateFlowCubit>();
  late final _landmark = TextEditingController(text: _cubit.state.draft.landmark);
  final _districtKey = GlobalKey();
  bool _locating = false;

  /// Why "Aniqlash" did not pick a district.
  String? _locateNote;

  @override
  void dispose() {
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locateNote = null;
    });
    final r = await getIt<LocationService>().current();
    if (!mounted) return;
    setState(() => _locating = false);
    r.match(
      (problem) => setState(
        () => _locateNote = switch (problem) {
          LocationProblem.denied || LocationProblem.deniedForever => tr('Joylashuvga ruxsat yoʻq — tumanni oʻzingiz tanlang'),
          _ => problem.message,
        },
      ),
      (here) async {
        final place = Regions.locate(here);
        if (place == null) {
          setState(() => _locateNote = tr('Siz Oʻzbekistondan tashqaridasiz — hududni oʻzingiz tanlang'));
          return;
        }
        _cubit.setCity(place.city);
        // Outside Tashkent the district comes from the geocoder's name.
        var district = place.district;
        if (district == null) {
          setState(() => _locating = true);
          final area = await getIt<Geocoder>().areaFor(here.approximate());
          if (!mounted) return;
          setState(() => _locating = false);
          district = Regions.matchDistrict(place.city, area?.district);
        }
        if (district == null) {
          setState(() => _locateNote = tr('Hudud aniqlandi: {city}. Tumanni tanlang.', {'city': tr(place.city)}));
          return;
        }
        _cubit.setDistrict(district, point: here);
      },
    );
  }

  Future<void> _pickCity(BuildContext anchor) async {
    final current = _cubit.state.draft.city;
    final v = await showPullDownMenu(
      context,
      anchor: anchor,
      label: tr('Shahar / viloyat'),
      items: [for (final c in Regions.cities) (c, tr(c))],
      current: current,
    );
    if (v == null || v == current || !mounted) return;
    setState(() => _locateNote = null);
    _cubit.setCity(v);
  }

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    var picked = _cubit.state.draft.happenedAt(now);
    if (picked.isAfter(now)) picked = now;
    final done = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Container(
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
                      CupertinoButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Bekor qilish'))),
                      const Spacer(),
                      CupertinoButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(tr('Tayyor'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 216,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    use24hFormat: true,
                    initialDateTime: picked,
                    minimumDate: now.subtract(const Duration(days: 90)),
                    maximumDate: now,
                    onDateTimeChanged: (d) => picked = d,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (done != true) return;
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(picked.year, picked.month, picked.day);
    if (day == today) {
      _cubit.setDay(DraftDay.today);
    } else if (day == today.subtract(const Duration(days: 1))) {
      _cubit.setDay(DraftDay.yesterday);
    } else {
      _cubit.setDay(DraftDay.other, date: day);
    }
    _cubit.setTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocConsumer<CreateFlowCubit, CreateFlowState>(
      listenWhen: (a, b) => a.attempt != b.attempt && b.showAreaError,
      listener: (_, _) {
        final ctx = _districtKey.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), alignment: 0.1);
      },
      builder: (context, state) {
        final d = state.draft;
        final happened = d.happenedAt(DateTime.now());
        final districtError = state.showAreaError ? DraftValidator.district(d) : null;
        return ListView(
          controller: widget.controller,
          physics: createScrollPhysics,
          padding: EdgeInsets.fromLTRB(20, widget.top, 20, createFormBottomPadding(context)),
          children: [
            KeyedSubtree(
              key: _districtKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CreateSectionLabel(
                    label: d.isFound ? tr('Qaysi tumanda topdingiz?') : tr('Qaysi tumanda yoʻqotdingiz?'),
                    value: tr(d.city),
                    onValuePick: _pickCity,
                    error: districtError != null,
                  ),
                  _DistrictChips(
                    // A new region starts its row from the beginning.
                    key: ValueKey(d.city),
                    city: d.city,
                    selected: d.district,
                    locating: _locating,
                    onLocate: _locate,
                    onSelected: (name) {
                      setState(() => _locateNote = null);
                      _cubit.setDistrict(name);
                    },
                  ),
                  if (districtError != null)
                    CreateError(districtError)
                  else if (_locateNote != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(_locateNote!, style: TextStyle(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CreateField(
              label: tr('Moʻljal · ixtiyoriy'),
              controller: _landmark,
              icon: Symbols.near_me_rounded,
              hint: tr('Masalan: metro bekati, doʻkon yonida'),
              maxLength: CreateDraft.maxLandmark,
              onChanged: _cubit.setLandmark,
            ),
            const SizedBox(height: 8),
            CreateNote(
              icon: Symbols.visibility_rounded,
              text: tr('Eʼlonda faqat tuman va moʻljal koʻrinadi, aniq manzil emas.'),
            ),
            const SizedBox(height: 14),
            CreateSectionLabel(
              label: d.isFound ? tr('Qachon topdingiz?') : tr('Qachon yoʻqotdingiz?'),
              value: '${TDate.dayMonth(happened)} · ${TDate.time(happened)}',
              onValueTap: _pickWhen,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CreateChip(
                  label: tr('Bugun'),
                  fontSize: 15,
                  selected: d.day == DraftDay.today,
                  onTap: () => _cubit.setDay(DraftDay.today),
                ),
                CreateChip(
                  label: tr('Kecha'),
                  fontSize: 15,
                  selected: d.day == DraftDay.yesterday,
                  onTap: () => _cubit.setDay(DraftDay.yesterday),
                ),
                CreateChip(label: tr('Boshqa sana'), fontSize: 15, selected: d.day == DraftDay.other, onTap: _pickWhen),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// "Aniqlash" then the districts, one scrolling row; the chosen one is kept in view.
class _DistrictChips extends StatefulWidget {
  const _DistrictChips({
    super.key,
    required this.city,
    required this.selected,
    required this.locating,
    required this.onLocate,
    required this.onSelected,
  });

  final String city;
  final String? selected;
  final bool locating;
  final VoidCallback onLocate;
  final ValueChanged<String> onSelected;

  @override
  State<_DistrictChips> createState() => _DistrictChipsState();
}

class _DistrictChipsState extends State<_DistrictChips> {
  late final _keys = {for (final d in Regions.districtsOf(widget.city)) d: GlobalKey()};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(animate: false));
  }

  @override
  void didUpdateWidget(_DistrictChips old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void _reveal({bool animate = true}) {
    final s = widget.selected;
    final ctx = s == null ? null : _keys[s]?.currentContext;
    if (ctx == null || !ctx.mounted) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: animate ? const Duration(milliseconds: 250) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final districts = Regions.districtsOf(widget.city);
    return SizedBox(
      height: 44,
      // Runs to both screen edges, past the 20 side padding.
      child: OverflowBox(
        minWidth: MediaQuery.sizeOf(context).width,
        maxWidth: MediaQuery.sizeOf(context).width,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: districts.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            if (i == 0) {
              return CreateChip(
                label: tr('Aniqlash'),
                accent: true,
                selected: false,
                icon: Symbols.my_location_rounded,
                leading: widget.locating
                    ? SizedBox.square(dimension: 18, child: CupertinoActivityIndicator(radius: 8, color: cs.onPrimaryContainer))
                    : null,
                onTap: widget.onLocate,
              );
            }
            final name = districts[i - 1];
            return CreateChip(
              key: _keys[name],
              label: tr(name),
              selected: name == widget.selected,
              onTap: () => widget.onSelected(name),
            );
          },
        ),
      ),
    );
  }
}
