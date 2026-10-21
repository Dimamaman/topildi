import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/t_text.dart';
import 'glass_surface.dart';

/// iOS 26 large-title layout shared by the glass pages (Lenta, Mening
/// eʼlonlarim): a pinned row of 44dp glass buttons, then a 34px title that
/// scrolls under it and reappears inline in the bar.
abstract final class GlassHeader {
  /// Screen side padding.
  static const side = 16.0;

  /// Bar: 44 buttons + 8 below.
  static const barHeight = 44.0 + 8;

  /// Large title: 14 above (8 in the bar + 6 here), 41 line, 14 below.
  static const titleTop = 6.0, titleLine = 41.0, titleBottom = 14.0;
  static const titleExtent = titleTop + titleLine + titleBottom;

  /// Space above the bar: the status bar, plus a little when it is short (Android).
  static double top(BuildContext context) {
    final t = MediaQuery.paddingOf(context).top;
    return t + (t < 30 ? 8 : 0);
  }

  /// Inline-title opacity for a scroll [offset]: fades in as the large title passes under the bar.
  static double inlineOpacity(double offset) => ((offset - titleTop - titleLine * 0.6) / 16).clamp(0.0, 1.0);
}

/// Translucent blurred page background for pinned bars, so content
/// scrolling underneath shows through softly. Only the backdrop is clipped,
/// so the glass buttons' shadows are not cut off.
class GlassBarBackground extends StatelessWidget {
  const GlassBarBackground({super.key, required this.child, this.offset, this.hairlineAt = 0});

  final Widget child;

  /// When given, a hairline shows along the bottom once the scroll offset reaches [hairlineAt].
  final ValueListenable<double>? offset;
  final double hairlineAt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final o = offset;
    Widget hairline(bool show) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: show ? cs.outlineVariant : Colors.transparent, width: 0.5)),
      ),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: ColoredBox(
                color: cs.surface.withValues(alpha: 0.86),
                child: o == null
                    ? const SizedBox.expand()
                    : ValueListenableBuilder<double>(
                        valueListenable: o,
                        builder: (context, v, _) => hairline(v > hairlineAt),
                      ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// 34px large title; scrolls under the glass bar.
class GlassLargeTitle extends StatelessWidget {
  const GlassLargeTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GlassHeader.side + 4,
        GlassHeader.titleTop,
        GlassHeader.side + 4,
        GlassHeader.titleBottom,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium!
              .copyWith(fontSize: 34, height: GlassHeader.titleLine / 34, letterSpacing: -0.7)
              .inter(FontWeight.w700),
        ),
      ),
    );
  }
}

/// 17px inline title that fades in once the large title is gone.
class GlassInlineTitle extends StatelessWidget {
  const GlassInlineTitle(this.text, {super.key, required this.offset});

  final String text;
  final ValueListenable<double> offset;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: offset,
      builder: (context, o, child) => Opacity(opacity: GlassHeader.inlineOpacity(o), child: child),
      child: ExcludeSemantics(
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(fontSize: 17, height: 22 / 17).inter(FontWeight.w600),
        ),
      ),
    );
  }
}

/// 44×44 glass circle button with an optional status dot (8×8, 2px rim).
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    required this.semantic,
    required this.onTap,
    this.dot,
    this.iconSize = 22,
  });

  final IconData icon;
  final String semantic;
  final VoidCallback onTap;
  final Color? dot;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: 44,
          child: GlassSurface(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: iconSize, color: cs.onSurface),
                if (dot != null)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surfaceContainerLowest, width: 2),
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
