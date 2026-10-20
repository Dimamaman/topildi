import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Pull-to-refresh that feels native on each platform:
/// - iOS: bouncing scroll with [CupertinoSliverRefreshControl] (the spinner
///   is revealed inside the overscroll, then the list settles back).
/// - Android & others: Material [RefreshIndicator] (circle slides over the
///   content) with clamping scroll.
class TRefreshScrollView extends StatelessWidget {
  const TRefreshScrollView({super.key, required this.onRefresh, required this.slivers, this.controller});

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.platform == TargetPlatform.iOS) {
      return CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          ...slivers,
        ],
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
