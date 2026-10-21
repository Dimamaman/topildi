import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glass_surface.dart';
import '../l10n/tr.dart';

/// Opens an iOS 26 floating glass sheet over everything (tab bar included):
/// 8dp inside the screen edges, 46dp concentric corners, a scrim that closes
/// it on tap, spring-in from the bottom and drag-down to dismiss. Android's
/// back button closes it too.
Future<T?> showGlassSheet<T>(BuildContext context, {required String label, required WidgetBuilder builder}) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push(GlassSheetRoute<T>(builder: builder, label: label, scrim: context.glass.scrim));
}

class GlassSheetRoute<T> extends PopupRoute<T> {
  GlassSheetRoute({required this.builder, required this.label, required Color scrim}) : _scrim = scrim;

  final WidgetBuilder builder;
  final String label;
  final Color _scrim;

  /// Soft spring: a slight overshoot, gentler than [Curves.easeOutBack].
  static const _spring = Cubic(0.32, 1.18, 0.6, 1);

  @override
  Color? get barrierColor => _scrim;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => tr('Yopish');

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return _GlassSheetFrame(label: label, child: Builder(builder: builder));
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: _spring, reverseCurve: Curves.easeInCubic);
    return SlideTransition(
      position: curved.drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
      child: child,
    );
  }
}

class _GlassSheetFrame extends StatefulWidget {
  const _GlassSheetFrame({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  State<_GlassSheetFrame> createState() => _GlassSheetFrameState();
}

class _GlassSheetFrameState extends State<_GlassSheetFrame> with SingleTickerProviderStateMixin {
  /// How far the sheet is dragged down.
  double _dy = 0;
  late final AnimationController _settle;
  double _settleFrom = 0;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..addListener(() => setState(() => _dy = _settleFrom * (1 - Curves.easeOutCubic.transform(_settle.value))));
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _drag(double delta) {
    if (_settle.isAnimating) _settle.stop();
    setState(() => _dy = math.max(0, _dy + delta));
  }

  void _release(double velocity) {
    if (_dy > 120 || velocity > 700) {
      Navigator.of(context).maybePop();
      return;
    }
    _settleFrom = _dy;
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final g = context.glass;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(8, mq.padding.top + 8, 8, 8 + mq.viewInsets.bottom),
      child: Transform.translate(
        offset: Offset(0, _dy),
        child: GestureDetector(
          onVerticalDragUpdate: (d) => _drag(d.delta.dy),
          onVerticalDragEnd: (d) => _release(d.primaryVelocity ?? 0),
          // Pulling down past the top of the content drags the sheet.
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is OverscrollNotification && n.dragDetails != null && n.overscroll < 0) {
                _drag(-n.overscroll);
              } else if (n is ScrollUpdateNotification && _dy > 0 && n.dragDetails != null) {
                _drag(-(n.scrollDelta ?? 0));
              } else if (n is ScrollEndNotification && _dy > 0) {
                _release(n.dragDetails?.primaryVelocity ?? 0);
              }
              return false;
            },
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: widget.label,
              child: GlassSurface(
                radius: 46,
                blur: 30,
                // Page colour, so the white / #182031 groups stand out in both themes.
                color: cs.surface.withValues(alpha: 0.9),
                rim: g.sheetRim,
                shadowColor: g.sheetShadow,
                shadowBlur: 60,
                shadowOffset: 20,
                padding: const EdgeInsets.all(14),
                child: Material(type: MaterialType.transparency, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
