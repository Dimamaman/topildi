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

/// iOS 26 Liquid Glass pull-down menu, opened under [anchor] (the row it
/// belongs to) with its right edge on the row's right edge; above the row
/// when there is no room below. No dimming; a tap outside or the back
/// button closes it. [dividersAfter] puts a thin separator after those
/// item indexes. Shown in an overlay entry rather than a route, so a finger
/// still pressed on the row (see [PullDownDrag]) is not cancelled.
Future<T?> showPullDownMenu<T>(
  BuildContext context, {
  required BuildContext anchor,
  required List<(T, String)> items,
  required T current,
  String? label,
  Set<int> dividersAfter = const {},
  PullDownDrag? drag,
}) {
  final overlay = Navigator.of(context, rootNavigator: true).overlay!;
  final overlayBox = overlay.context.findRenderObject()! as RenderBox;
  final box = anchor.findRenderObject()! as RenderBox;
  final rect = box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
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
        dividersAfter: dividersAfter,
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
    required this.dividersAfter,
    required this.drag,
  });

  final Rect anchor;
  final List<(T, String)> items;
  final T current;
  final String? label;
  final Set<int> dividersAfter;
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
    return BoxConstraints.tightFor(width: w, height: height);
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
    final height = math.min(wanted, up ? above : below);
    final scrollable = content > height;

    final rows = <Widget>[];
    for (var i = 0; i < spec.items.length; i++) {
      final (value, label) = spec.items[i];
      final selected = value == spec.current;
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
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
            decoration: BoxDecoration(
              color: _hover == i ? g.menuPressed : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: selected ? Icon(Symbols.check_rounded, size: 20, color: cs.onSurface) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge!
                        .copyWith(fontSize: 17, height: 22 / 17, color: cs.onSurface)
                        .inter(selected ? FontWeight.w600 : FontWeight.w400),
                  ),
                ),
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
        physics: scrollable ? null : const NeverScrollableScrollPhysics(),
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
