import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/topildi_theme.dart';

enum AvatarTone { primary, lost, neutral }

/// Initials avatar. Only first name + surname initial are ever shown publicly.
class TAvatar extends StatelessWidget {
  const TAvatar({super.key, this.initials, this.size = 40, this.tone = AvatarTone.primary, this.verified = false});

  final String? initials;
  final double size;
  final AvatarTone tone;
  final bool verified;

  /// "Dilshod A." → "DA".
  static String initialsOf(String displayName) {
    final parts = displayName.replaceAll('.', '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = context.tc;
    final (bg, fg) = switch (tone) {
      AvatarTone.primary => (cs.primaryContainer, cs.onPrimaryContainer),
      AvatarTone.lost => (tc.lostContainer, tc.lost),
      AvatarTone.neutral => (cs.surfaceContainerHigh, cs.onSurfaceVariant),
    };
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: initials == null
          ? Icon(Symbols.person_rounded, size: size / 2, color: fg)
          : Text(
              initials!,
              textScaler: TextScaler.noScaling,
              style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w700, color: fg),
            ),
    );
    if (!verified) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: tc.success,
              shape: BoxShape.circle,
              border: Border.all(color: cs.surface, width: 2),
            ),
            child: Icon(Symbols.check_rounded, size: 12, color: cs.surface, weight: 700),
          ),
        ),
      ],
    );
  }
}
