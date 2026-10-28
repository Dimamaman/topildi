import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/media/photo_picker.dart';
import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../listing/domain/entities/listing.dart';
import '../../domain/entities/create_draft.dart';
import '../cubit/create_flow_cubit.dart';
import '../pages/create_flow_page.dart';
import 'create_ui.dart';
import '../../../../core/l10n/tr.dart';

/// Step 1: found/lost and photos.
class CreateTypeStep extends StatelessWidget {
  const CreateTypeStep({super.key, required this.controller, required this.top});

  final ScrollController controller;

  /// Room above the form for the preview card.
  final double top;

  static const _tile = 96.0;

  Future<void> _pick(CreateFlowCubit cubit, PhotoSource source) async {
    final path = await getIt<PhotoPicker>().pick(source);
    if (path != null) cubit.addPhoto(path);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateFlowCubit>();
    final tc = context.tc;

    return BlocBuilder<CreateFlowCubit, CreateFlowState>(
      buildWhen: (a, b) => a.draft.type != b.draft.type || a.draft.photos != b.draft.photos || a.isEditing != b.isEditing,
      builder: (context, state) {
        final d = state.draft;
        final full = d.photos.length >= CreateDraft.maxPhotos;
        return ListView(
          controller: controller,
          physics: createScrollPhysics,
          padding: EdgeInsets.fromLTRB(20, top, 20, createFormBottomPadding(context)),
          children: [
            CreateSectionLabel(label: tr('Nima boʻldi?')),
            // The type can't change once posted.
            IgnorePointer(
              ignoring: state.isEditing,
              child: Opacity(
                opacity: state.isEditing ? 0.5 : 1,
                child: _TypeSegment(isFound: d.isFound, onChanged: cubit.setType),
              ),
            ),
            const SizedBox(height: 18),
            CreateSectionLabel(label: tr('Rasmlar'), value: '${d.photos.length} / ${CreateDraft.maxPhotos}'),
            SizedBox(
              height: _tile,
              child: Row(
                children: [
                  _SourceTile(
                    primary: true,
                    icon: Symbols.photo_camera_rounded,
                    label: tr('Kamera'),
                    onTap: full ? null : () => _pick(cubit, PhotoSource.camera),
                  ),
                  const SizedBox(width: 8),
                  _SourceTile(
                    primary: false,
                    icon: Symbols.photo_library_rounded,
                    label: tr('Galereya'),
                    onTap: full ? null : () => _pick(cubit, PhotoSource.gallery),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: d.photos.isEmpty
                        ? const _EmptyPhotos()
                        : _PhotoStrip(photos: d.photos, onRemove: cubit.removePhoto, onMove: cubit.movePhoto),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            CreateNote(
              icon: Symbols.visibility_off_rounded,
              color: tc.warning,
              text: tr('Karta raqami, hujjat va ichidagi narsalar rasmda koʻrinmasin.'),
            ),
          ],
        );
      },
    );
  }
}

/// 60-high capsule: Topdim | Yoʻqotdim, a white thumb under the chosen half.
class _TypeSegment extends StatelessWidget {
  const _TypeSegment({required this.isFound, required this.onChanged});

  final bool isFound;
  final ValueChanged<ListingType> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = CreateColors.of(context);
    final tc = context.tc;
    return Container(
      height: 60,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.segment, borderRadius: BorderRadius.circular(999)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: isFound ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: c.segmentThumb,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [BoxShadow(color: Color(0x1A0F1420), offset: Offset(0, 3), blurRadius: 10)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: _SegmentOption(
                    selected: isFound,
                    icon: Symbols.volunteer_activism_rounded,
                    label: tr('Topdim'),
                    color: tc.found,
                    onTap: () => onChanged(ListingType.found),
                  ),
                ),
                Expanded(
                  child: _SegmentOption(
                    selected: !isFound,
                    icon: Symbols.search_rounded,
                    label: tr('Yoʻqotdim'),
                    color: tc.lost,
                    onTap: () => onChanged(ListingType.lost),
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

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          if (!selected) HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge!
                    .copyWith(fontSize: 16, height: 22 / 16, color: selected ? color : cs.secondary)
                    .inter(selected ? FontWeight.w700 : FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 96×96 Kamera (primary) or Galereya (white, hairline) tile; dimmed at 6 photos.
class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.primary, required this.icon, required this.label, required this.onTap});

  final bool primary;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = primary ? cs.onPrimary : cs.primary;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: onTap == null ? 0.45 : 1,
          child: Container(
            width: CreateTypeStep._tile,
            height: CreateTypeStep._tile,
            decoration: BoxDecoration(
              color: primary ? cs.primary : cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: primary ? null : Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, fill: 1, color: fg),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium!.copyWith(fontSize: 13, height: 16 / 13, color: fg).inter(FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dashed frame: "6 tagacha rasm".
class _EmptyPhotos extends StatelessWidget {
  const _EmptyPhotos();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _DashedRRectPainter(color: CreateColors.of(context).dashed, radius: 24),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            tr('6 tagacha rasm'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!
                .copyWith(fontSize: 13, height: 18 / 13, color: cs.onSurfaceVariant)
                .inter(FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(0.75), Radius.circular(radius)));
    for (final ui.PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) => old.color != color || old.radius != radius;
}

/// Picked photos, 96×96; long-press drags to reorder (the first is the main one).
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos, required this.onRemove, required this.onMove});

  final List<String> photos;
  final ValueChanged<int> onRemove;
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: photos.length,
      proxyDecorator: (child, _, _) => Material(type: MaterialType.transparency, child: child),
      onReorder: (from, to) => onMove(from, to > from ? to - 1 : to),
      itemBuilder: (context, i) => Padding(
        key: ValueKey(photos[i]),
        padding: EdgeInsets.only(right: i == photos.length - 1 ? 0 : 8),
        child: _PhotoThumb(path: photos[i], index: i, onRemove: () => onRemove(i)),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.path, required this.index, required this.onRemove});

  final String path;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: tr('{n}-rasm', {'n': index + 1}),
      child: SizedBox.square(
        dimension: CreateTypeStep._tile,
        child: Stack(
          children: [
            Positioned.fill(
              child: PhotoPlaceholder(
                icon: Symbols.image_rounded,
                tint: index,
                path: path,
                width: CreateTypeStep._tile,
                height: CreateTypeStep._tile,
                iconSize: 32,
                radius: 24,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Semantics(
                button: true,
                label: tr('Rasmni oʻchirish'),
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onRemove,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox.square(
                    dimension: 44,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: Color(0xB30F1420), shape: BoxShape.circle),
                        child: const Icon(Symbols.close_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
