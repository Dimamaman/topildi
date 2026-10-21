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
    required this.panel,
    required this.control,
    required this.scrim,
    required this.sheetRim,
    required this.sheetShadow,
    required this.menu,
    required this.menuRim,
    required this.menuShadow,
    required this.menuPressed,
    required this.menuDivider,
    required this.menuSourceOpen,
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

  /// Floating bottom action panel (Eʼlon detail).
  final Color panel;

  /// Buttons inside a glass sheet (Yopish, Tozalash).
  final Color control;

  /// Dimmed page behind a floating sheet.
  final Color scrim;

  /// Floating sheet's inner rim and drop shadow.
  final Color sheetRim, sheetShadow;

  /// Pull-down menu: material, rim, shadow, pressed row, group divider.
  final Color menu, menuRim, menuShadow, menuPressed, menuDivider;

  /// The capsule a pull-down menu was opened from, while it is open.
  final Color menuSourceOpen;

  final Color rimTop, rim, rimBottom, shadow;

  static const _light = TGlass._(
    fill: Color(0xB3FFFFFF),
    bar: Color(0x9EFFFFFF),
    thumb: Color(0xEBFFFFFF),
    tag: Color(0xBFFFFFFF),
    activeTab: Color(0x24767680),
    quiet: Color(0x1F767680),
    tile: Color(0xB8FFFFFF),
    panel: Color(0xB8FFFFFF),
    control: Color(0xCCFFFFFF),
    scrim: Color(0x470F1420),
    sheetRim: Color(0x80FFFFFF),
    sheetShadow: Color(0x470F1420),
    menu: Color(0xE0FAFBFD),
    menuRim: Color(0x8CFFFFFF),
    menuShadow: Color(0x380F1420),
    menuPressed: Color(0x29767680),
    menuDivider: Color(0x2E3C3C43),
    menuSourceOpen: Color(0x29767680),
    rimTop: Color(0xF2FFFFFF),
    rim: Color(0x73FFFFFF),
    rimBottom: Color(0x59FFFFFF),
    shadow: Color(0x1F0F1420),
  );

  static const _dark = TGlass._(
    fill: Color(0x992A3550),
    bar: Color(0xB3212A3D),
    thumb: Color(0x8C5D6A84),
    tag: Color(0xBF182031),
    activeTab: Color(0x1AFFFFFF),
    quiet: Color(0x3D767680),
    tile: Color(0x730F1420),
    panel: Color(0xBF212A3D),
    control: Color(0x3D767680),
    scrim: Color(0x73000000),
    sheetRim: Color(0x2EFFFFFF),
    sheetShadow: Color(0x99000000),
    menu: Color(0xE0212A3D),
    menuRim: Color(0x2EFFFFFF),
    menuShadow: Color(0x80000000),
    menuPressed: Color(0x1AFFFFFF),
    menuDivider: Color(0x1FFFFFFF),
    menuSourceOpen: Color(0x47767680),
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
  const GlassSurface({
    super.key,
    required this.child,
    this.color,
    this.radius = 999,
    this.padding,
    this.shadow = true,
    this.blur = 18,
    this.shadowColor,
    this.shadowBlur = 28,
    this.shadowOffset = 8,
    this.rim,
  });

  final Widget child;

  /// Fill; defaults to [TGlass.fill].
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final bool shadow;

  /// Backdrop blur radius.
  final double blur;

  /// Drop shadow `0 [shadowOffset] [shadowBlur] [shadowColor]`; colour defaults to [TGlass.shadow].
  final Color? shadowColor;
  final double shadowBlur, shadowOffset;

  /// Rim colour along the sides and bottom; defaults to [TGlass.rim] / [TGlass.rimBottom].
  final Color? rim;

  static final _filter18 = _filter(18);

  static ImageFilter _filter(double blur) => ImageFilter.compose(
    outer: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
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
      painter: shadow
          ? _OuterShadowPainter(
              radius: radius,
              color: shadowColor ?? g.shadow,
              blur: shadowBlur,
              offset: shadowOffset,
            )
          : null,
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: blur == 18 ? _filter18 : _filter(blur),
          child: CustomPaint(
            foregroundPainter: _RimPainter(
              radius: radius,
              top: g.rimTop,
              mid: rim ?? g.rim,
              bottom: rim ?? g.rimBottom,
            ),
            child: Container(padding: padding, color: color ?? g.fill, child: child),
          ),
        ),
      ),
    );
  }
}

/// `0 offset blur color`, clipped to the outside of the rounded rect.
class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter({required this.radius, required this.color, required this.blur, required this.offset});

  final double radius, blur, offset;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect((Offset.zero & size).inflate(blur * 3 + offset)),
        Path()..addRRect(rrect),
      ),
    );
    canvas.drawRRect(
      rrect.shift(Offset(0, offset)),
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, Shadow.convertRadiusToSigma(blur)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter old) =>
      old.radius != radius || old.color != color || old.blur != blur || old.offset != offset;
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
