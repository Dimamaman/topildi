import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'glass_surface.dart';
import '../theme/t_text.dart';
import '../config/features.dart';
import '../l10n/tr.dart';

/// Floating Liquid Glass tab bar (iOS 26 style, used on both platforms):
/// a glass capsule with Lenta · Xarita · Chatlar · Profil, and next to it a
/// round primary "+" that starts the Eʼlon berish flow (an action, not a tab).
/// Floats over the content: host it with `Scaffold(extendBody: true)`.
/// [currentIndex]: 0 Lenta, 1 Xarita, 2 Chatlar, 3 Profil.
class TBottomNav extends StatelessWidget {
  const TBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
    this.unreadChats = 0,
    this.showMap = Features.map,
  });

  /// Shell branch of the current tab (0 Lenta, 1 Xarita, 2 Chatlar, 3 Profil).
  final int currentIndex;

  /// Called with the shell branch of the tapped tab.
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final int unreadChats;

  static const barHeight = 62.0;

  /// Show the Xarita tab. Hidden tabs keep their branch number, so the
  /// shell's branches never shift.
  final bool showMap;

  static const _chatsBranch = 2;

  /// (shell branch, icon, label) of each visible tab.
  List<(int, IconData, String)> get _items => [
    (0, Symbols.home_rounded, tr('Lenta')),
    if (showMap) (1, Symbols.map_rounded, tr('Xarita')),
    (_chatsBranch, Symbols.chat_bubble_rounded, tr('Chatlar')),
    (3, Symbols.account_circle_rounded, tr('Profil')),
  ];

  /// Gap under the bar: 24 above the screen edge, never inside the
  /// home-indicator / gesture area.
  static double bottomGap(BuildContext context) => math.max(24, MediaQuery.paddingOf(context).bottom - 10);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final g = context.glass;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomGap(context)),
      child: SizedBox(
        height: barHeight,
        child: Row(
          children: [
            Expanded(
              child: GlassSurface(
                color: g.bar,
                padding: const EdgeInsets.all(4),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final items = _items;
                    final w = c.maxWidth / items.length;
                    final active = math.max(0, items.indexWhere((t) => t.$1 == currentIndex));
                    return Stack(
                      children: [
                        // Active-tab capsule slides between tabs.
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          left: w * active,
                          top: 0,
                          bottom: 0,
                          width: w,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: g.activeTab, borderRadius: BorderRadius.circular(999)),
                          ),
                        ),
                        Row(
                          children: [
                            for (final (branch, icon, label) in items)
                              Expanded(
                                child: _Tab(
                                  icon: icon,
                                  label: label,
                                  active: branch == currentIndex,
                                  badge: branch == _chatsBranch ? unreadChats : 0,
                                  onTap: () {
                                    if (branch != currentIndex) HapticFeedback.selectionClick();
                                    onSelect(branch);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: tr('Eʼlon berish'),
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onAdd,
                behavior: HitTestBehavior.opaque,
                child: SizedBox.square(
                  dimension: barHeight,
                  child: GlassSurface(
                    color: cs.primary.withValues(alpha: 0.88),
                    child: Center(child: Icon(Symbols.add_rounded, size: 30, color: cs.onPrimary)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.label, required this.active, required this.badge, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = active ? cs.primary : cs.onSurface;
    return Semantics(
      button: true,
      selected: active,
      label: badge > 0 ? tr('{label}, {badge} ta yangi', {'label': label, 'badge': badge}) : label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 24, color: color, fill: 1),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    left: 17,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: cs.error, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        '$badge',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(fontSize: 11, height: 1, fontWeight: FontWeight.w600, color: cs.onError),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
              style: Theme.of(context).textTheme.labelSmall!
                  .copyWith(fontSize: 10, height: 1.3, letterSpacing: 0, color: color)
                  .inter(active ? FontWeight.w600 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
