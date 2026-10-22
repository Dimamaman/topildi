import 'package:flutter/material.dart';

import '../theme/topildi_theme.dart';

/// Colours of the signed-in user's letter avatar (picked on "Tanishib
/// olaylik"): 0 primary, 1 green, 2 peach, 3 yellow → (background, letter).
(Color, Color) avatarToneColors(BuildContext context, int tone) {
  final cs = Theme.of(context).colorScheme;
  final tc = context.tc;
  return switch (tone) {
    1 => (tc.foundContainer, tc.found),
    2 => (tc.lostContainer, tc.lost),
    3 => (tc.warningContainer, tc.warning),
    _ => (cs.primary, cs.onPrimary),
  };
}
