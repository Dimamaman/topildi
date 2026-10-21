import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Liquid Glass colours (iOS 26 style). Fills are translucent so whatever
/// scrolls underneath shows through the blur.
@immutable
class TGlass {
  const TGlass._({
    required this.fill,
    required this.bar,
    required this.thumb,
    required this.tag,
    required this.activeTab,
    required this.quiet,
    required this.tile,
    required this.rimTop,
    required this.rim,
    required this.rimBottom,
    required this.shadow,
  });

  /// Buttons and the location capsule.
  final Color fill;

  /// Floating tab bar.
  final Color bar;

  /// Selected segment of the Topilgan / Yoʻqolgan control.
  final Color thumb;

  /// Tags laid over listing photos.
  final Color tag;

  /// Capsule behind the active tab.
  final Color activeTab;

  /// Neutral fill for tracks, unselected chips and the card chevron.
  final Color quiet;

  /// Stat tiles on a tinted header card (Profil).
  final Color tile;

  final Color rimTop, rim, rimBottom, shadow;

  static const _light = TGlass._(
    fill: Color(0xB3FFFFFF),
    bar: Color(0x9EFFFFFF),
    thumb: Color(0xEBFFFFFF),
    tag: Color(0xBFFFFFFF),
    activeTab: Color(0x24767680),
    quiet: Color(0x1F767680),
    tile: Color(0xB8FFFFFF),
    rimTop: Color(0xF2FFFFFF),
    rim: Color(0x73FFFFFF),
    rimBottom: Color(0x59FFFFFF),
    shadow: Color(0x1F0F1420),
  );

  static const _dark = TGlass._(
    fill: Color(0x992A3550),
    bar: Color(0xB3212A3D),
    thumb: Color(0xEB2A3550),
    tag: Color(0xBF182031),
    activeTab: Color(0x1AFFFFFF),
    quiet: Color(0x3D767680),
    tile: Color(0x730F1420),
    rimTop: Color(0x38FFFFFF),
    rim: Color(0x1AFFFFFF),
    rimBottom: Color(0x1AFFFFFF),
    shadow: Color(0x73000000),
  );

  static TGlass of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

extension TGlassX on BuildContext {
  TGlass get glass => TGlass.of(this);
}

/// Liquid Glass material: backdrop blur + saturation, translucent fill,
/// a thin light rim (brighter along the top edge) and a soft drop shadow
/// that is painted only outside the shape, so it never greys the glass.
class GlassSurface extends StatelessWidget {
  const GlassSurface({super.key, required this.child, this.color, this.radius = 999, this.padding, this.shadow = true});

  final Widget child;

  /// Fill; defaults to [TGlass.fill].
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final bool shadow;

  static final _filter = ImageFilter.compose(
    outer: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
    inner: const ColorFilter.matrix(_saturate180),
  );

  // Saturation 1.8 (CSS saturate(180%)).
  static const List<double> _saturate180 = [
    1.5726, -0.5154, -0.0572, 0, 0, //
    -0.1274, 1.2846, -0.1572, 0, 0, //
    -0.1274, -0.5154, 1.6428, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final g = context.glass;
    final r = BorderRadius.circular(radius);
    return CustomPaint(
      painter: shadow ? _OuterShadowPainter(radius: radius, color: g.shadow) : null,
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: _filter,
          child: CustomPaint(
            foregroundPainter: _RimPainter(radius: radius, top: g.rimTop, mid: g.rim, bottom: g.rimBottom),
            child: Container(padding: padding, color: color ?? g.fill, child: child),
          ),
        ),
      ),
    );
  }
}

/// `0 8 28 shadow`, clipped to the outside of the rounded rect.
class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect((Offset.zero & size).inflate(80)),
        Path()..addRRect(rrect),
      ),
    );
    canvas.drawRRect(
      rrect.shift(const Offset(0, 8)),
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, Shadow.convertRadiusToSigma(28)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter old) => old.radius != radius || old.color != color;
}

/// 1px inner rim with a highlight along the top edge.
class _RimPainter extends CustomPainter {
  const _RimPainter({required this.radius, required this.top, required this.mid, required this.bottom});

  final double radius;
  final Color top, mid, bottom;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, mid, mid, bottom],
          stops: const [0, 0.3, 0.7, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.radius != radius || old.top != top || old.mid != mid || old.bottom != bottom;
}
