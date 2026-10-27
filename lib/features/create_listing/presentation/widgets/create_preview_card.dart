import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/t_text.dart';
import '../../../../core/theme/topildi_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/photo_placeholder.dart';
import '../../../listing/presentation/category_ui.dart';
import '../../domain/entities/create_draft.dart';
import 'create_ui.dart';
import '../../../../core/l10n/tr.dart';

/// "EʼLONINGIZ SHUNDAY KOʻRINADI": a live copy of the feed card, tilted
/// −2°, that fills in as the form does (photo, then title and category,
/// then district and time). It only shows, never takes taps.
class CreatePreviewCard extends StatefulWidget {
  const CreatePreviewCard({super.key, required this.draft, required this.showWhen});

  final CreateDraft draft;

  /// Step 3: the type chip also says when ("Topilgan · Bugun, 09:40").
  final bool showWhen;

  static const photoHeight = 128.0;

  @override
  State<CreatePreviewCard> createState() => _CreatePreviewCardState();
}

class _CreatePreviewCardState extends State<CreatePreviewCard> with SingleTickerProviderStateMixin {
  static const _tilt = -2 * math.pi / 180;

  /// −2° → −4° → −2° when a photo is added.
  late final _wobble = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final _angle = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: _tilt, end: 2 * _tilt).chain(CurveTween(curve: Curves.easeOut)), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 2 * _tilt, end: _tilt).chain(CurveTween(curve: Curves.easeIn)), weight: 1),
  ]).animate(_wobble);

  @override
  void didUpdateWidget(CreatePreviewCard old) {
    super.didUpdateWidget(old);
    if (widget.draft.photos.length > old.draft.photos.length && !MediaQuery.disableAnimationsOf(context)) {
      _wobble.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  String _when(DateTime at, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final label = day == today
        ? tr('Bugun')
        : day == today.subtract(const Duration(days: 1))
        ? tr('Kecha')
        : TDate.dayMonth(at);
    return '$label, ${TDate.time(at)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final text = Theme.of(context).textTheme;
    final c = CreateColors.of(context);
    final d = widget.draft;
    final title = d.title.trim();
    final category = d.category;
    final district = d.district;
    final meta = [?category?.label, if (district != null) tr(district)].join(' · ');
    final typeColor = d.isFound ? tc.found : tc.lost;
    final typeLabel = d.isFound ? tr('Topilgan') : tr('Yoʻqolgan');
    final chip = widget.showWhen ? '$typeLabel · ${_when(d.happenedAt(DateTime.now()), DateTime.now())}' : typeLabel;
    const fade = Duration(milliseconds: 200);

    final Widget photo;
    if (d.photos.isNotEmpty) {
      photo = PhotoPlaceholder(
        key: ValueKey(d.photos.first),
        icon: category?.icon ?? Symbols.image_rounded,
        path: d.photos.first,
        height: CreatePreviewCard.photoHeight,
        width: double.infinity,
        iconSize: 56,
        radius: 0,
      );
    } else if (category != null) {
      // Same rule as the feed: the category's colour and icon.
      photo = PhotoPlaceholder(
        key: ValueKey(category),
        icon: category.icon,
        tint: category.index,
        height: CreatePreviewCard.photoHeight,
        width: double.infinity,
        iconSize: 56,
        radius: 0,
      );
    } else {
      photo = Container(
        key: const ValueKey('empty'),
        color: c.cardPhoto,
        alignment: Alignment.center,
        child: Icon(Symbols.add_a_photo_rounded, size: 34, color: c.cardPhotoIcon),
      );
    }

    return Semantics(
      label: tr('Eʼlon koʻrinishi: {title}, {category}', {'title': title, 'category': category?.label ?? ''}),
      excludeSemantics: true,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _angle,
          builder: (context, child) => Transform.rotate(angle: _angle.value, child: child),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [BoxShadow(color: Color(0x291D45A8), offset: Offset(0, 20), blurRadius: 44)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: CreatePreviewCard.photoHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedSwitcher(duration: fade, child: photo),
                      Positioned(
                        left: 10,
                        top: 10,
                        right: 10,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _GlassChip(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    chip,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.labelSmall!
                                        .copyWith(fontSize: 11, height: 14 / 11, color: typeColor)
                                        .inter(FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (d.photos.isNotEmpty)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: _GlassChip(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Symbols.photo_library_rounded, size: 14, color: cs.onSurface),
                                const SizedBox(width: 4),
                                Text(
                                  '${d.photos.length}',
                                  style: text.labelSmall!
                                      .copyWith(fontSize: 11, height: 14 / 11, color: cs.onSurface)
                                      .inter(FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: fade,
                        layoutBuilder: _topLeft,
                        child: title.isEmpty
                            ? _Bar(key: const ValueKey('title-bar'), widthFactor: 0.7, height: 14, color: c.bar, lineHeight: 21)
                            : Text(
                                title,
                                // A key per state, not per letter: typing updates in place.
                                key: const ValueKey('title'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleMedium!
                                    .copyWith(fontSize: 16, height: 21 / 16, color: cs.onSurface)
                                    .inter(FontWeight.w700),
                              ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: fade,
                        layoutBuilder: _topLeft,
                        child: meta.isEmpty
                            ? _Bar(key: const ValueKey('meta-bar'), widthFactor: 0.5, height: 10, color: c.barSoft, lineHeight: 16)
                            : Text(
                                meta,
                                key: ValueKey(meta),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall!
                                    .copyWith(fontSize: 12, height: 16 / 12, color: cs.onSurfaceVariant)
                                    .inter(FontWeight.w400),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _topLeft(Widget? current, List<Widget> previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      );
}

/// 24-high glass capsule on the preview photo.
class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      color: context.glass.tag,
      child: Container(
        height: 24,
        padding: const EdgeInsets.only(left: 7, right: 9),
        child: Center(widthFactor: 1, child: child),
      ),
    );
  }
}

/// Rounded grey bar standing in for text not entered yet.
class _Bar extends StatelessWidget {
  const _Bar({super.key, required this.widthFactor, required this.height, required this.color, required this.lineHeight});

  final double widthFactor, height, lineHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: lineHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(height / 2)),
          ),
        ),
      ),
    );
  }
}
