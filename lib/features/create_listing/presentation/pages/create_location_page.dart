import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/topildi_surfaces.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/t_button.dart';
import '../../../../core/widgets/t_chip.dart';
import '../../../../core/widgets/t_top_bar.dart';
import '../../domain/entities/create_draft.dart';
import '../cubit/create_flow_cubit.dart';
import '../widgets/create_header.dart';

/// Step 3: approximate area (~300 m) and when it happened.
class CreateLocationPage extends StatefulWidget {
  const CreateLocationPage({super.key, this.editing = false});

  final bool editing;

  @override
  State<CreateLocationPage> createState() => _CreateLocationPageState();
}

class _CreateLocationPageState extends State<CreateLocationPage> {
  // Mock areas until a real map/geocoder is wired in.
  static const _areas = ['Chilonzor-9, metro bekati yonida', 'Chilonzor-7, bozor yonida', 'Novza, metro chiqishi'];
  int _areaIndex = 0;

  late final CreateFlowCubit _cubit = context.read<CreateFlowCubit>();

  @override
  void initState() {
    super.initState();
    final current = _cubit.state.draft.areaName;
    if (current == null) {
      _cubit.setArea(_areas.first);
    } else {
      _areaIndex = math.max(0, _areas.indexOf(current));
    }
  }

  void _moveArea() {
    setState(() => _areaIndex = (_areaIndex + 1) % _areas.length);
    _cubit.setArea(_areas[_areaIndex]);
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
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: d.hour, minute: d.minute));
    if (picked != null) _cubit.setTime(picked.hour, picked.minute);
  }

  void _next() {
    if (!_cubit.submitLocation()) return;
    widget.editing ? context.pop() : context.push(Routes.createReview);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const CreateHeader(title: 'Qayerda va qachon?', step: 3),
      body: BlocBuilder<CreateFlowCubit, CreateFlowState>(
        builder: (context, state) {
          final d = state.draft;
          final happened = d.happenedAt(DateTime.now());
          return ListView(
            children: [
              SizedBox(height: 330, child: _AreaPicker(onMove: _moveArea, onLocate: _moveArea)),
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
                            d.areaName ?? 'Joy belgilanmagan',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Boshqalarga aniq nuqta emas, taxminan 300 m lik hudud koʻrsatiladi.',
                      style: TextStyle(fontSize: 13, height: 19 / 13, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      d.isFound ? 'Qachon topdingiz?' : 'Qachon yoʻqotdingiz?',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: TSpace.xs,
                      children: [
                        TChip(label: 'Bugun', selected: d.day == DraftDay.today, onTap: () => _cubit.setDay(DraftDay.today)),
                        TChip(
                          label: 'Kecha',
                          selected: d.day == DraftDay.yesterday,
                          onTap: () => _cubit.setDay(DraftDay.yesterday),
                        ),
                        TChip(label: 'Boshqa sana', selected: d.day == DraftDay.other, onTap: _pickDate),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _PickerField(label: 'Sana', value: TDate.dayMonth(happened), onTap: _pickDate)),
                        const SizedBox(width: 10),
                        Expanded(child: _PickerField(label: 'Taxminiy vaqt', value: TDate.time(happened), onTap: _pickTime)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: TBottomBar(
        horizontal: TSpace.screen,
        children: [TButton.primary(label: widget.editing ? 'Saqlash' : 'Koʻrib chiqish', onPressed: _next)],
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TRadius.md), side: BorderSide(color: cs.outline)),
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

/// Stylised map with a fixed ~300 m area circle in the centre.
/// Tapping/dragging the map simulates moving the area.
class _AreaPicker extends StatelessWidget {
  const _AreaPicker({required this.onMove, required this.onLocate});

  final VoidCallback onMove, onLocate;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onMove,
      onPanEnd: (_) => onMove(),
      child: Container(
        color: ts.map,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            ExcludeSemantics(
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 40,
                    child: Container(
                      width: 120,
                      height: 90,
                      decoration: BoxDecoration(color: ts.park, borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    right: -20,
                    top: 230,
                    child: Transform.rotate(angle: -0.14, child: Container(height: 50, color: ts.water)),
                  ),
                  Positioned(
                    left: -20,
                    right: -20,
                    top: 150,
                    child: Transform.rotate(angle: 0.09, child: Container(height: 12, color: ts.road)),
                  ),
                  Positioned(top: 0, bottom: 0, left: 200, width: 12, child: ColoredBox(color: ts.road)),
                ],
              ),
            ),
            Center(
              child: CustomPaint(
                painter: _DashedCirclePainter(fill: cs.primary.withValues(alpha: 0.14), stroke: cs.primary),
                child: SizedBox.square(
                  dimension: 160,
                  child: Icon(Symbols.location_on_rounded, size: 40, color: cs.primary, fill: 1),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: cs.inverseSurface, borderRadius: BorderRadius.circular(18)),
                  child: Text(
                    'Xaritani surib, joyni belgilang',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onInverseSurface),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: Material(
                color: cs.surfaceContainerLowest,
                elevation: 2,
                shadowColor: cs.scrim.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(TRadius.md),
                child: IconButton(
                  tooltip: 'Mening joylashuvim',
                  onPressed: onLocate,
                  icon: Icon(Symbols.my_location_rounded, color: cs.primary),
                ),
              ),
            ),
          ],
        ),
      ),
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
