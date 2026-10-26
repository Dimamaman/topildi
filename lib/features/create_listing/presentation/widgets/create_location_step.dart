import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/config/features.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/location/geo_point.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/map/map_tiles.dart';
import '../../../../core/widgets/t_feedback.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/pull_down_menu.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_chip.dart';
import '../../../listing/domain/entities/regions.dart';
import '../../domain/entities/create_draft.dart';
import '../cubit/create_flow_cubit.dart';
import '../../../../core/l10n/tr.dart';

/// Step 3: approximate area (~300 m) and when it happened.
class CreateLocationStep extends StatefulWidget {
  const CreateLocationStep({super.key});

  @override
  State<CreateLocationStep> createState() => _CreateLocationStepState();
}

class _CreateLocationStepState extends State<CreateLocationStep> {
  late final CreateFlowCubit _cubit = context.read<CreateFlowCubit>();
  final _map = MapController();
  final _location = getIt<LocationService>();
  final _geocoder = getIt<Geocoder>();
  late GeoPoint _center = _cubit.state.draft.point ?? GeoPoint.tashkent;
  bool _resolving = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    if (_cubit.state.draft.point == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locate(quiet: true));
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _locate({bool quiet = false}) async {
    final r = await _location.current();
    if (!mounted) return;
    r.match(
      (problem) {
        // No permission: start from the city centre; the user can still pan.
        if (!quiet) TFeedback.error(context, problem.message);
        _resolve(_center);
      },
      (g) {
        // The map is only on screen when the feature is on.
        if (Features.map) _map.move(LatLng(g.lat, g.lng), 16);
        _resolve(g);
      },
    );
  }

  /// Snaps the map centre to its ~300 m cell and names it.
  Future<void> _resolve(GeoPoint center) async {
    final cell = center.approximate();
    final id = ++_request;
    setState(() {
      _center = center;
      _resolving = true;
    });
    final info = await _geocoder.areaFor(cell);
    if (!mounted || id != _request) return;
    setState(() => _resolving = false);
    _cubit.setArea(info?.name ?? tr('Belgilangan hudud'), cell, district: info?.district);
  }

  /// Without the map: place the listing at the chosen district's centre.
  Future<void> _pickDistrict(BuildContext anchor) async {
    final picked = await showPullDownMenu(
      context,
      anchor: anchor,
      label: tr('Tumanni tanlang'),
      items: [for (final d in Regions.tashkentDistricts) (d, d)],
      current: _cubit.state.draft.district,
    );
    if (picked == null || !mounted) return;
    final (lat, lng) = Regions.tashkentDistrictCenters[picked]!;
    _request++; // Drop any GPS lookup still in flight.
    setState(() => _resolving = false);
    _cubit.setArea(picked, GeoPoint(lat, lng), district: picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now,
      initialDate: _cubit.state.draft.happenedAt(now),
    );
    if (picked != null) _cubit.setDay(DraftDay.other, date: picked);
  }

  Future<void> _pickTime() async {
    final d = _cubit.state.draft;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: d.hour, minute: d.minute),
    );
    if (picked != null) _cubit.setTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<CreateFlowCubit, CreateFlowState>(
      builder: (context, state) {
        final d = state.draft;
        final happened = d.happenedAt(DateTime.now());
        return ListView(
          children: [
            if (Features.map)
              SizedBox(
                height: 330,
                child: _AreaPicker(controller: _map, initial: _center, onMoved: _resolve, onLocate: _locate),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(TSpace.screen, TSpace.md, TSpace.screen, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TButton.secondary(
                        label: tr('Joylashuvim'),
                        icon: Symbols.my_location_rounded,
                        onPressed: _locate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Builder(
                        builder: (anchor) => TButton.secondary(
                          label: tr('Tumanni tanlash'),
                          icon: Symbols.list_rounded,
                          onPressed: () => _pickDistrict(anchor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TSpace.screen, vertical: TSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Symbols.location_on_rounded, size: 20, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _resolving ? tr('Hudud aniqlanmoqda…') : (d.areaName ?? tr('Joy belgilanmagan')),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('Boshqalarga aniq nuqta emas, taxminan 300 m lik hudud koʻrsatiladi.'),
                    style: TextStyle(fontSize: 13, height: 19 / 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    d.isFound ? tr('Qachon topdingiz?') : tr('Qachon yoʻqotdingiz?'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: TSpace.xs,
                    children: [
                      TChip(
                        label: tr('Bugun'),
                        selected: d.day == DraftDay.today,
                        onTap: () => _cubit.setDay(DraftDay.today),
                      ),
                      TChip(
                        label: tr('Kecha'),
                        selected: d.day == DraftDay.yesterday,
                        onTap: () => _cubit.setDay(DraftDay.yesterday),
                      ),
                      TChip(label: tr('Boshqa sana'), selected: d.day == DraftDay.other, onTap: _pickDate),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerField(label: tr('Sana'), value: TDate.dayMonth(happened), onTap: _pickDate),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PickerField(
                          label: tr('Taxminiy vaqt'),
                          value: TDate.time(happened),
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.value, required this.onTap});

  final String label, value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TRadius.md),
        side: BorderSide(color: cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TSize.input),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive map; the ~300 m area stays fixed in the middle while the
/// user pans underneath it.
class _AreaPicker extends StatelessWidget {
  const _AreaPicker({required this.controller, required this.initial, required this.onMoved, required this.onLocate});

  final MapController controller;
  final GeoPoint initial;
  final ValueChanged<GeoPoint> onMoved;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: LatLng(initial.lat, initial.lng),
              initialZoom: 15.5,
              minZoom: 12,
              maxZoom: 18,
              backgroundColor: context.ts.map,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onMapEvent: (e) {
                if (e is MapEventMoveEnd || e is MapEventFlingAnimationEnd || e is MapEventDoubleTapZoomEnd) {
                  onMoved(GeoPoint(e.camera.center.latitude, e.camera.center.longitude));
                }
              },
            ),
            children: const [TopildiTileLayer()],
          ),
        ),
        // Fixed centre overlay: dashed ~300 m circle + pin.
        IgnorePointer(
          child: Center(
            child: CustomPaint(
              painter: _DashedCirclePainter(fill: cs.primary.withValues(alpha: 0.14), stroke: cs.primary),
              child: SizedBox.square(
                dimension: 160,
                child: Icon(Symbols.location_on_rounded, size: 40, color: cs.primary, fill: 1),
              ),
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: cs.inverseSurface, borderRadius: BorderRadius.circular(18)),
                child: Text(
                  tr('Xaritani surib, joyni belgilang'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onInverseSurface),
                ),
              ),
            ),
          ),
        ),
        const Positioned(left: 0, bottom: 0, child: OsmAttribution()),
        Positioned(
          right: 14,
          bottom: 14,
          child: Material(
            color: cs.surfaceContainerLowest,
            elevation: 2,
            shadowColor: cs.scrim.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(TRadius.md),
            child: IconButton(
              tooltip: tr('Mening joylashuvim'),
              onPressed: onLocate,
              icon: Icon(Symbols.my_location_rounded, color: cs.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.fill, required this.stroke});

  final Color fill, stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
    canvas.drawCircle(center, r, Paint()..color = fill);
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dashes = 36;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.fill != fill || old.stroke != stroke;
}
