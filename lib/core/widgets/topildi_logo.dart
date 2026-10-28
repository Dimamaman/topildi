import 'package:flutter/material.dart';

import '../theme/t_text.dart';

/// Brand colours of the "t." logo.
abstract final class BrandColors {
  /// Icon background, top-left → bottom-right.
  static const gradientFrom = Color(0xFF3A72F0), gradientTo = Color(0xFF1D45A8);
  static const blue = Color(0xFF2B5FD9);

  /// Dot on blue / dark backgrounds and on white ones.
  static const dotOnDark = Color(0xFFFBD38D), dotOnLight = Color(0xFFF3A77E);
  static const ink = Color(0xFF172033);
}

/// The "t." mark from `assets/brand/svg`, in its 106×140 box (x 66…172,
/// y 40…180 of the 200 grid).
abstract final class TopildiMarkPath {
  static const box = Rect.fromLTWH(66, 40, 106, 140);
  static const dotCenter = Offset(152, 150);
  static const dotRadius = 13.0;

  /// `M86 46h24v30h26v22h-26v42c0 8 4 11 11 11h15v22h-20c-20 0-30-10-30-30v-45H72V76h14z`
  static Path stem() => Path()
    ..moveTo(86, 46)
    ..relativeLineTo(24, 0)
    ..relativeLineTo(0, 30)
    ..relativeLineTo(26, 0)
    ..relativeLineTo(0, 22)
    ..relativeLineTo(-26, 0)
    ..relativeLineTo(0, 42)
    ..relativeCubicTo(0, 8, 4, 11, 11, 11)
    ..relativeLineTo(15, 0)
    ..relativeLineTo(0, 22)
    ..relativeLineTo(-20, 0)
    ..relativeCubicTo(-20, 0, -30, -10, -30, -30)
    ..relativeLineTo(0, -45)
    ..lineTo(72, 98)
    ..lineTo(72, 76)
    ..relativeLineTo(14, 0)
    ..close();

  /// Paints the mark in the 200-unit grid; the caller sets the transform.
  static void paint(Canvas canvas, {required Color stem, required Color dot}) {
    canvas.drawPath(TopildiMarkPath.stem(), Paint()..color = stem);
    canvas.drawCircle(dotCenter, dotRadius, Paint()..color = dot);
  }
}

/// The "t." mark alone, [height] tall (width follows the 106:140 box).
/// White with a yellow dot by default, for blue backgrounds.
class TopildiMark extends StatelessWidget {
  const TopildiMark({
    super.key,
    required this.height,
    this.color = Colors.white,
    this.dot = BrandColors.dotOnDark,
  });

  /// Blue mark with the peach dot, for white backgrounds.
  const TopildiMark.blue({super.key, required this.height})
    : color = BrandColors.blue,
      dot = BrandColors.dotOnLight;

  final double height;
  final Color color, dot;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: height * TopildiMarkPath.box.width / TopildiMarkPath.box.height,
    height: height,
    child: CustomPaint(painter: _MarkPainter(color: color, dot: dot)),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.color, required this.dot});

  final Color color, dot;

  @override
  void paint(Canvas canvas, Size size) {
    const box = TopildiMarkPath.box;
    final k = size.height / box.height;
    canvas
      ..scale(k)
      ..translate(-box.left, -box.top);
    TopildiMarkPath.paint(canvas, stem: color, dot: dot);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color || old.dot != dot;
}

/// App icon tile: gradient squircle with the white mark, [size] square.
class TopildiAppIcon extends StatelessWidget {
  const TopildiAppIcon({super.key, required this.size, this.radius, this.shadow = const []});

  final double size;

  /// Corner radius; defaults to the icon's own (45 on the 200 grid).
  final double? radius;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius ?? size * 45 / 200),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [BrandColors.gradientFrom, BrandColors.gradientTo],
      ),
      boxShadow: shadow,
    ),
    // The mark sits at (47.5, 30.5) of the 200 grid, 140 tall.
    child: Padding(
      padding: EdgeInsets.only(left: size * 47.5 / 200, top: size * 30.5 / 200),
      child: Align(alignment: Alignment.topLeft, child: TopildiMark(height: size * 140 / 200)),
    ),
  );
}

/// "topildi." wordmark, Inter 800 at [fontSize], −4% tracking. [onDark]
/// switches to white text and the yellow dot.
class TopildiWordmark extends StatelessWidget {
  const TopildiWordmark({super.key, required this.fontSize, this.onDark = false});

  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      height: 1,
      letterSpacing: -0.04 * fontSize,
      color: onDark ? Colors.white : BrandColors.ink,
    ).inter(FontWeight.w800);
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'topildi'),
          TextSpan(
            text: '.',
            style: TextStyle(color: onDark ? BrandColors.dotOnDark : BrandColors.dotOnLight),
          ),
        ],
      ),
      style: style,
      semanticsLabel: 'Topildi',
      textScaler: TextScaler.noScaling,
    );
  }
}
