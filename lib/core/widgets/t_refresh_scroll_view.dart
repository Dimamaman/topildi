import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Pull-to-refresh that feels native on each platform:
/// - iOS: bouncing scroll with [CupertinoSliverRefreshControl] (the spinner
///   is revealed inside the overscroll, then the list settles back).
/// - Android & others: Material [RefreshIndicator] (circle slides over the
///   content) with clamping scroll.
class TRefreshScrollView extends StatelessWidget {
  const TRefreshScrollView({
    super.key,
    required this.onRefresh,
    required this.slivers,
    this.controller,
    this.overscrollColor,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollController? controller;

  /// iOS: colour revealed above the first sliver while pulling. Pass the
  /// first sliver's background (e.g. a header) so it appears to stretch
  /// instead of opening an empty gap. Later slivers must paint their own
  /// background, since this colour sits behind the whole scroll view.
  final Color? overscrollColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.platform == TargetPlatform.iOS) {
      final scroll = CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: onRefresh,
            refreshTriggerPullDistance: 90,
            refreshIndicatorExtent: 52,
          ),
          ...slivers,
        ],
      );
      final color = overscrollColor;
      if (color == null) return scroll;
      return LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Positioned(top: 0, left: 0, right: 0, height: c.maxHeight / 2, child: ColoredBox(color: color)),
            scroll,
          ],
        ),
      );
    }
    final cs = theme.colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: cs.primary,
      backgroundColor: cs.surfaceContainerLowest,
      child: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        slivers: slivers,
      ),
    );
  }
}
