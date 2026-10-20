import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/topildi_theme.dart';

/// Bottom nav: Lenta · Xarita · Qoʻshish · Chatlar · Profil.
/// Index 2 ("Qoʻshish") is an action, not a destination: it calls [onAdd].
/// iOS gets a Cupertino-style tab bar, everything else the Material 3 bar.
/// [currentIndex] is the destination index (0 Lenta, 1 Xarita, 3 Chatlar, 4 Profil).
class TBottomNav extends StatelessWidget {
  const TBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
    this.unreadChats = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final int unreadChats;

  static const _items = [
    (Symbols.home_rounded, 'Lenta'),
    (Symbols.map_rounded, 'Xarita'),
    (Symbols.add_rounded, 'Qoʻshish'),
    (Symbols.chat_bubble_rounded, 'Chatlar'),
    (Symbols.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return _CupertinoNav(
        items: _items,
        currentIndex: currentIndex,
        unreadChats: unreadChats,
        onTap: (i) => i == 2 ? onAdd() : onSelect(i),
      );
    }
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: TSize.navBar + bottom,
      padding: EdgeInsets.only(left: 8, right: 8, bottom: bottom),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: _NavItem(
                icon: _items[i].$1,
                label: _items[i].$2,
                active: i == currentIndex,
                isAdd: i == 2,
                badge: i == 3 ? unreadChats : 0,
                onTap: () => i == 2 ? onAdd() : onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.isAdd,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active, isAdd;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = active ? cs.onPrimaryContainer : (isAdd ? cs.onSurface : cs.onSurfaceVariant);
    final pill = Container(
      width: isAdd ? 40 : 56,
      height: 30,
      decoration: BoxDecoration(
        color: isAdd ? cs.primary : (active ? cs.primaryContainer : Colors.transparent),
        borderRadius: BorderRadius.circular(isAdd ? 10 : 15),
      ),
      child: Icon(icon, size: isAdd ? 20 : 22, color: isAdd ? cs.onPrimary : fg, fill: active ? 1 : 0),
    );
    return Semantics(
      button: true,
      selected: active,
      label: badge > 0 ? '$label, $badge ta yangi' : label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  pill,
                  if (badge > 0)
                    Positioned(
                      top: -4,
                      right: 2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: cs.error, borderRadius: BorderRadius.circular(9)),
                        child: Text(
                          '$badge',
                          textScaler: TextScaler.noScaling,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onError),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active || isAdd ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS tab bar: 50 pt, translucent blurred background, hairline top border,
/// tinted (not pill-highlighted) selection, opacity press feedback.
class _CupertinoNav extends StatelessWidget {
  const _CupertinoNav({
    required this.items,
    required this.currentIndex,
    required this.unreadChats,
    required this.onTap,
  });

  final List<(IconData, String)> items;
  final int currentIndex, unreadChats;
  final ValueChanged<int> onTap;

  static const _height = 50.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: _height + bottom,
          padding: EdgeInsets.only(bottom: bottom),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest.withValues(alpha: 0.92),
            border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _CupertinoItem(
                    icon: i == 2 ? Symbols.add_circle_rounded : items[i].$1,
                    label: items[i].$2,
                    active: i == currentIndex,
                    isAdd: i == 2,
                    badge: i == 3 ? unreadChats : 0,
                    onTap: () {
                      if (i != currentIndex) HapticFeedback.selectionClick();
                      onTap(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CupertinoItem extends StatelessWidget {
  const _CupertinoItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.isAdd,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active, isAdd;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = active || isAdd ? cs.primary : cs.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: active,
      label: badge > 0 ? '$label, $badge ta yangi' : label,
      excludeSemantics: true,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(TSize.tapTarget, _CupertinoNav._height),
        pressedOpacity: 0.5,
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fixed icon box keeps all labels on one baseline.
            SizedBox(
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: isAdd ? 30 : 26, color: color, fill: active || isAdd ? 1 : 0),
                  if (badge > 0)
                    Positioned(
                      top: -3,
                      right: -10,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '$badge',
                          textScaler: TextScaler.noScaling,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
