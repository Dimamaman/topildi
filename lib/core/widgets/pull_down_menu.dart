import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/t_text.dart';
import 'glass_surface.dart';

/// Feeds a still-pressed finger into an open pull-down menu (iOS
/// press-and-drag): the source row reports moves and the release, the menu
/// highlights the row under the finger and picks it on release.
class PullDownDrag extends ChangeNotifier {
  Offset? _position;
  bool _released = false;

  Offset? get position => _position;
  bool get released => _released;

  void move(Offset global) {
    _position = global;
    notifyListeners();
  }

  void release() {
    _released = true;
    notifyListeners();
  }
}

/// iOS 26 Liquid Glass pull-down menu, opened under [anchor] (the row or
/// button it belongs to; or the global rect [at]) with its right edge on the
/// anchor's right edge; above it when there is no room below. No dimming; a
/// tap outside or the back button closes it. [dividersAfter] puts a thin
/// separator after those item indexes. A pick menu checks [current]; an
/// action menu (no item is [current]) has no check column and shows
/// [icons] at the trailing edge. Shown in an overlay entry rather than a
/// route, so a finger still pressed on the row (see [PullDownDrag]) is not
/// cancelled.
Future<T?> showPullDownMenu<T>(
  BuildContext context, {
  BuildContext? anchor,
  Rect? at,
  required List<(T, String)> items,
  T? current,
  String? label,
  Map<int, IconData> icons = const {},
  Set<int> dividersAfter = const {},
  Set<int> destructive = const {},
  PullDownDrag? drag,
}) {
  assert((anchor == null) != (at == null), 'Pass exactly one of anchor and at');
  final overlay = Navigator.of(context, rootNavigator: true).overlay!;
  final overlayBox = overlay.context.findRenderObject()! as RenderBox;
  final Rect rect;
  if (anchor != null) {
    final box = anchor.findRenderObject()! as RenderBox;
    rect = box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
  } else {
    rect = at!;
  }
  final completer = Completer<T?>();
  final route = ModalRoute.of(context);
  late final OverlayEntry entry;
  late final LocalHistoryEntry history;
  var inHistory = true;
  final menuKey = GlobalKey<_PullDownMenuState<T>>();

  void finish(T? value) {
    if (completer.isCompleted) return;
    completer.complete(value);
    if (inHistory) route?.removeLocalHistoryEntry(history);
    entry.remove();
  }

  // Back button closes the menu first (Android).
  history = LocalHistoryEntry(
    onRemove: () {
      inHistory = false;
      menuKey.currentState?.close(null);
    },
  );
  route?.addLocalHistoryEntry(history);

  entry = OverlayEntry(
    builder: (_) => _PullDownMenu<T>(
      key: menuKey,
      spec: _MenuSpec(
        anchor: rect,
        items: items,
        current: current,
        label: label,
        icons: icons,
        dividersAfter: dividersAfter,
        destructive: destructive,
        drag: drag,
      ),
      onClosed: finish,
    ),
  );
  overlay.insert(entry);
  return completer.future;
}

class _MenuSpec<T> {
  const _MenuSpec({
    required this.anchor,
    required this.items,
    required this.current,
    required this.label,
    required this.icons,
    required this.dividersAfter,
    required this.destructive,
    required this.drag,
  });

  final Rect anchor;
  final List<(T, String)> items;
  final T? current;
  final String? label;

  /// Trailing icons by item index.
  final Map<int, IconData> icons;
  final Set<int> dividersAfter;

  /// Items drawn in the error colour (e.g. "Rasmni olib tashlash").
  final Set<int> destructive;
  final PullDownDrag? drag;

  static const width = 236.0;
  static const rowHeight = 44.0;
  static const gap = 6.0;
}

class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout({required this.anchor, required this.up, required this.height, required this.padding});

  final Rect anchor;
  final bool up;
  final double height;
  final EdgeInsets padding;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final w = math.min(_MenuSpec.width, constraints.maxWidth - 16);
    // Loose height: a row whose label wraps onto a second line makes the
    // menu taller (up to [height]) instead of hanging past its clipped
    // edge, where it would not even take a tap.
    return BoxConstraints(minWidth: w, maxWidth: w, maxHeight: height);
  }

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (anchor.right - child.width).clamp(8.0, size.width - 8 - child.width);
    final y = up ? anchor.top - _MenuSpec.gap - child.height : anchor.bottom + _MenuSpec.gap;
    return Offset(x, y.clamp(padding.top + 8, math.max(padding.top + 8, size.height - padding.bottom - 8 - child.height)));
  }

  @override
  bool shouldRelayout(_MenuLayout old) =>
      old.anchor != anchor || old.up != up || old.height != height || old.padding != padding;
}

class _PullDownMenu<T> extends StatefulWidget {
  const _PullDownMenu({super.key, required this.spec, required this.onClosed});

  final _MenuSpec<T> spec;
  final ValueChanged<T?> onClosed;

  @override
  State<_PullDownMenu<T>> createState() => _PullDownMenuState<T>();
}

class _PullDownMenuState<T> extends State<_PullDownMenu<T>> with SingleTickerProviderStateMixin {
  late final List<GlobalKey> _keys = [for (final _ in widget.spec.items) GlobalKey()];
  late final AnimationController _anim;
  int? _hover;
  bool _closing = false;

  /// Soft spring with a slight overshoot.
  static const _spring = Cubic(0.34, 1.36, 0.64, 1);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 180),
    )..forward();
    widget.spec.drag?.addListener(_onDrag);
  }

  @override
  void dispose() {
    widget.spec.drag?.removeListener(_onDrag);
    _anim.dispose();
    super.dispose();
  }

  /// Plays the closing animation, then reports [value] (null = dismissed).
  Future<void> close(T? value) async {
    if (_closing) return;
    _closing = true;
    await _anim.reverse();
    widget.onClosed(value);
  }

  int? _indexAt(Offset global) {
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      if ((box.localToGlobal(Offset.zero) & box.size).contains(global)) return i;
    }
    return null;
  }

  void _onDrag() {
    final d = widget.spec.drag!;
    if (d.released) {
      if (_hover != null) _select(_hover!);
      return;
    }
    if (d.position != null) _setHover(_indexAt(d.position!));
  }

  void _setHover(int? i) {
    if (i != _hover) setState(() => _hover = i);
  }

  void _select(int i) {
    if (_closing) return;
    HapticFeedback.selectionClick();
    close(widget.spec.items[i].$1);
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final g = context.glass;
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final curved = CurvedAnimation(parent: _anim, curve: _spring, reverseCurve: Curves.easeIn);
    final fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut, reverseCurve: Curves.easeIn);

    // Row = 10 + 22px line (scaled) + 10, at least 44.
    final row = math.max(_MenuSpec.rowHeight, 20 + 22 * (mq.textScaler.scale(17) / 17));
    // At most 7.5 rows: the half-visible last row hints that it scrolls.
    final maxHeight = 16 + row * 7.5;
    final content = 16 + row * spec.items.length + spec.dividersAfter.length * 8.5;
    final below = mq.size.height - mq.padding.bottom - 8 - (spec.anchor.bottom + _MenuSpec.gap);
    final above = spec.anchor.top - _MenuSpec.gap - mq.padding.top - 8;
    final wanted = math.min(content, maxHeight);
    // Below the row when it fits, or when at least 4.5 rows fit (then it
    // scrolls); otherwise above it, if there is more room there.
    final up = wanted > below && below < 16 + row * 4.5 && above > below;
    // The cap, not the guess: with loose constraints the menu takes its real
    // height (a wrapped label makes a row taller than [row]) and stops here.
    final height = math.min(maxHeight, up ? above : below);
    final scrollable = content > height;
    // Pick menus keep a check column; action menus start with the label.
    final checks = spec.items.any((it) => it.$1 == spec.current);

    final rows = <Widget>[];
    for (var i = 0; i < spec.items.length; i++) {
      final (value, label) = spec.items[i];
      final selected = checks && value == spec.current;
      final color = spec.destructive.contains(i) ? cs.error : cs.onSurface;
      final icon = spec.icons[i];
      rows.add(
        Semantics(
          key: _keys[i],
          button: true,
          inMutuallyExclusiveGroup: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          onTap: () => _select(i),
          child: Container(
            constraints: const BoxConstraints(minHeight: _MenuSpec.rowHeight),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: EdgeInsets.fromLTRB(checks ? 8 : 12, 10, 12, 10),
            decoration: BoxDecoration(
              color: _hover == i ? g.menuPressed : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (checks) ...[
                  SizedBox(
                    width: 22,
                    child: selected ? Icon(Symbols.check_rounded, size: 20, color: cs.onSurface) : null,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge!
                        .copyWith(fontSize: 17, height: 22 / 17, color: color)
                        .inter(selected ? FontWeight.w600 : FontWeight.w400),
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 12),
                  Icon(icon, size: 21, color: color),
                ],
              ],
            ),
          ),
        ),
      );
      if (spec.dividersAfter.contains(i)) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Container(height: 0.5, color: g.menuDivider),
          ),
        );
      }
    }

    final list = NotificationListener<ScrollUpdateNotification>(
      // Actually scrolling the list is not a pick.
      onNotification: (n) {
        if ((n.scrollDelta ?? 0) != 0) _setHover(null);
        return false;
      },
      child: SingleChildScrollView(
        // The menu is only as tall as it needs to be, so this scrolls only
        // when the rows really do not fit.
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    );

    final menu = FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: Tween(begin: 0.6, end: 1.0).animate(curved),
        // Grows out of the source's top-right (bottom-right when opened upwards).
        alignment: up ? Alignment.bottomRight : Alignment.topRight,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: spec.label,
          child: GlassSurface(
            radius: 30,
            blur: 28,
            color: g.menu,
            rim: g.menuRim,
            shadowColor: g.menuShadow,
            shadowBlur: 50,
            shadowOffset: 18,
            child: Material(
              type: MaterialType.transparency,
              // Press, slide, release: the row under the finger is picked.
              child: Listener(
                onPointerDown: (e) => _setHover(_indexAt(e.position)),
                onPointerMove: (e) {
                  if (_hover != null || !scrollable) _setHover(_indexAt(e.position));
                },
                onPointerUp: (e) {
                  final i = _hover;
                  if (i != null && _indexAt(e.position) == i) _select(i);
                  _setHover(null);
                },
                onPointerCancel: (_) => _setHover(null),
                child: list,
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        // Invisible barrier: a tap anywhere outside closes the menu (no dimming).
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => close(null),
            excludeFromSemantics: true,
          ),
        ),
        CustomSingleChildLayout(
          delegate: _MenuLayout(anchor: spec.anchor, up: up, height: height, padding: mq.padding),
          child: BlockSemantics(child: menu),
        ),
      ],
    );
  }
}
