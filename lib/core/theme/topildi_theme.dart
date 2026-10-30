// Topildi — design tokens as Flutter ThemeData (Material 3).
// Direction "Aniq": calm blue primary, Inter, 12px radius, borders over shadows.
// Requires: google_fonts (or bundle Inter as an asset and set fontFamily: 'Inter').

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Spacing scale (4pt grid).
abstract final class TSpace {
  static const double xxs = 4, xs = 8, sm = 12, md = 16, lg = 20, xl = 24, x2l = 32, x3l = 40, x4l = 48;
  static const double screen = 20; // horizontal screen padding
}

/// Corner radii.
abstract final class TRadius {
  static const double xs = 6, sm = 8, md = 12, lg = 16, xl = 24, full = 999;
}

/// Fixed sizes.
abstract final class TSize {
  static const double tapTarget = 48, button = 52, input = 52, navBar = 80, cardPhoto = 104;
}

/// Found / Lost / status colours that are not part of ColorScheme.
@immutable
class TopildiColors extends ThemeExtension<TopildiColors> {
  const TopildiColors({
    required this.found,
    required this.foundContainer,
    required this.lost,
    required this.lostContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.photoPlaceholder,
    required this.primaryFill,
    required this.surfaceGlow,
    required this.onSurfaceSecondary,
    required this.onSurfaceMuted,
    required this.accentDot,
    required this.glassFill,
    required this.scrim,
  });

  final Color found, foundContainer, lost, lostContainer;
  final Color success, successContainer, warning, warningContainer;
  final Color photoPlaceholder;

  /// Filled surfaces (buttons, FAB, my chat bubble, `Switch`). Darker than
  /// [ColorScheme.primary] so white label text stays at AA on black.
  final Color primaryFill;

  /// Radial glow behind the top of a page.
  final Color surfaceGlow;

  /// Caption text one step above [ColorScheme.onSurfaceVariant].
  final Color onSurfaceSecondary;

  /// Placeholders, timestamps, disabled text.
  final Color onSurfaceMuted;

  /// Logo dot and decorative dots.
  final Color accentDot;

  /// Base fill of glass surfaces before the blur.
  final Color glassFill;

  /// Layer behind sheets and menus.
  final Color scrim;

  static const light = TopildiColors(
    found: Color(0xFF157347),
    foundContainer: Color(0xFFDFF3E8),
    lost: Color(0xFFA4441A),
    lostContainer: Color(0xFFFCEBDD),
    success: Color(0xFF1E7A4E),
    successContainer: Color(0xFFDFF3E8),
    warning: Color(0xFF8A5A12),
    warningContainer: Color(0xFFFDF1D8),
    photoPlaceholder: Color(0xFFDCE4F2),
    primaryFill: Color(0xFF2B5FD9),
    surfaceGlow: Color(0xFFE3EBFC),
    onSurfaceSecondary: Color(0xFF344055),
    onSurfaceMuted: Color(0xFF8A94A6),
    accentDot: Color(0xFFF3A77E),
    glassFill: Color(0xB3FFFFFF),
    scrim: Color(0x470F1420),
  );

  // OLED dark (D2): no green — "found"/"success" are the brand blue.
  static const dark = TopildiColors(
    found: Color(0xFF4D7FFF),
    foundContainer: Color(0xFF14234A),
    lost: Color(0xFFFF9F6E),
    lostContainer: Color(0xFF2A1A12),
    success: Color(0xFF4D7FFF),
    successContainer: Color(0xFF14234A),
    warning: Color(0xFFF2C46B),
    warningContainer: Color(0xFF2A2210),
    photoPlaceholder: Color(0xFF17181B),
    primaryFill: Color(0xFF3A6AF0),
    surfaceGlow: Color(0xFF0A1430),
    onSurfaceSecondary: Color(0xFFD0D4DC),
    onSurfaceMuted: Color(0xFF5F6672),
    accentDot: Color(0xFFF3A77E),
    glassFill: Color(0xD916171A),
    scrim: Color(0x99000000),
  );

  @override
  TopildiColors copyWith({
    Color? found,
    Color? foundContainer,
    Color? lost,
    Color? lostContainer,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? photoPlaceholder,
    Color? primaryFill,
    Color? surfaceGlow,
    Color? onSurfaceSecondary,
    Color? onSurfaceMuted,
    Color? accentDot,
    Color? glassFill,
    Color? scrim,
  }) =>
      TopildiColors(
        found: found ?? this.found,
        foundContainer: foundContainer ?? this.foundContainer,
        lost: lost ?? this.lost,
        lostContainer: lostContainer ?? this.lostContainer,
        success: success ?? this.success,
        successContainer: successContainer ?? this.successContainer,
        warning: warning ?? this.warning,
        warningContainer: warningContainer ?? this.warningContainer,
        photoPlaceholder: photoPlaceholder ?? this.photoPlaceholder,
        primaryFill: primaryFill ?? this.primaryFill,
        surfaceGlow: surfaceGlow ?? this.surfaceGlow,
        onSurfaceSecondary: onSurfaceSecondary ?? this.onSurfaceSecondary,
        onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
        accentDot: accentDot ?? this.accentDot,
        glassFill: glassFill ?? this.glassFill,
        scrim: scrim ?? this.scrim,
      );

  @override
  TopildiColors lerp(TopildiColors? other, double t) {
    if (other == null) return this;
    return TopildiColors(
      found: Color.lerp(found, other.found, t)!,
      foundContainer: Color.lerp(foundContainer, other.foundContainer, t)!,
      lost: Color.lerp(lost, other.lost, t)!,
      lostContainer: Color.lerp(lostContainer, other.lostContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      photoPlaceholder: Color.lerp(photoPlaceholder, other.photoPlaceholder, t)!,
      primaryFill: Color.lerp(primaryFill, other.primaryFill, t)!,
      surfaceGlow: Color.lerp(surfaceGlow, other.surfaceGlow, t)!,
      onSurfaceSecondary: Color.lerp(onSurfaceSecondary, other.onSurfaceSecondary, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      accentDot: Color.lerp(accentDot, other.accentDot, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension TopildiThemeX on BuildContext {
  TopildiColors get tc => Theme.of(this).extension<TopildiColors>()!;

  /// Glow under a filled blue element. The dark theme has no blue shadows —
  /// black at 40%, which over an OLED page reads as no shadow at all.
  Color primaryGlow(double opacity) {
    final cs = Theme.of(this).colorScheme;
    return cs.brightness == Brightness.dark
        ? const Color(0x66000000)
        : cs.primary.withValues(alpha: opacity);
  }
}

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF2B5FD9),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE3EBFC),
  onPrimaryContainer: Color(0xFF1D45A8),
  secondary: Color(0xFF344055),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFC2362B),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFBE3E0),
  onErrorContainer: Color(0xFF8C1F17),
  surface: Color(0xFFF4F6FA),
  onSurface: Color(0xFF172033),
  onSurfaceVariant: Color(0xFF556070),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFF4F6FA),
  surfaceContainerHigh: Color(0xFFEEF1F6),
  surfaceContainerHighest: Color(0xFFE6EAF1),
  outline: Color(0xFF8792A6),
  outlineVariant: Color(0xFFDCE2EC),
  inverseSurface: Color(0xFF172033),
  onInverseSurface: Color(0xFFE6EBF5),
  inversePrimary: Color(0xFF8DB0FF),
  scrim: Color(0xFF0F1420),
);

// OLED dark (D2): pure black page, near-black cards, brand blue that reads on black.
const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF4D7FFF),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF14234A),
  onPrimaryContainer: Color(0xFFB9CDFF),
  secondary: Color(0xFFD0D4DC),
  onSecondary: Color(0xFF000000),
  error: Color(0xFFFF6B5E),
  onError: Color(0xFF000000),
  errorContainer: Color(0xFF2A1211),
  onErrorContainer: Color(0xFFFF6B5E),
  surface: Color(0xFF000000),
  onSurface: Color(0xFFF2F4F8),
  onSurfaceVariant: Color(0xFF8E95A3),
  surfaceContainerLowest: Color(0xFF111214),
  surfaceContainerLow: Color(0xFF111214),
  surfaceContainer: Color(0xFF111214),
  surfaceContainerHigh: Color(0xFF17181B),
  surfaceContainerHighest: Color(0xFF1E1F23),
  outline: Color(0xFF26282D),
  outlineVariant: Color(0xFF26282D),
  inverseSurface: Color(0xFFF2F4F8),
  onInverseSurface: Color(0xFF111214),
  inversePrimary: Color(0xFF2B5FD9),
  scrim: Color(0xFF000000),
);

TextTheme _textTheme(Color onSurface) {
  final base = GoogleFonts.interTextTheme();
  TextStyle s(double size, double height, FontWeight w, [double ls = 0]) =>
      TextStyle(fontSize: size, height: height / size, fontWeight: w, letterSpacing: ls, color: onSurface);
  return base.copyWith(
    displaySmall: base.displaySmall!.merge(s(32, 40, FontWeight.w700, -0.64)),
    headlineMedium: base.headlineMedium!.merge(s(28, 36, FontWeight.w700, -0.28)),
    headlineSmall: base.headlineSmall!.merge(s(24, 32, FontWeight.w700, -0.24)),
    titleLarge: base.titleLarge!.merge(s(20, 28, FontWeight.w600)),
    titleMedium: base.titleMedium!.merge(s(16, 24, FontWeight.w600)),
    bodyLarge: base.bodyLarge!.merge(s(16, 24, FontWeight.w400)),
    bodyMedium: base.bodyMedium!.merge(s(14, 20, FontWeight.w400)),
    bodySmall: base.bodySmall!.merge(s(12, 16, FontWeight.w400)),
    labelLarge: base.labelLarge!.merge(s(14, 20, FontWeight.w600)),
    labelMedium: base.labelMedium!.merge(s(12, 16, FontWeight.w600, 0.12)),
  );
}

ThemeData _build(ColorScheme cs, TopildiColors ext) {
  final text = _textTheme(cs.onSurface);
  final r12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(TRadius.md));
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.surface,
    textTheme: text,
    extensions: [ext],
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      backgroundColor: cs.surfaceContainerLowest,
      foregroundColor: cs.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: cs.outlineVariant)),
      titleTextStyle: text.titleLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ext.primaryFill,
        foregroundColor: cs.onPrimary,
        minimumSize: const Size.fromHeight(TSize.button),
        shape: r12,
        textStyle: text.labelLarge!.copyWith(fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(TSize.button), shape: r12, side: BorderSide(color: cs.outline), textStyle: text.labelLarge!.copyWith(fontSize: 16)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(TSize.tapTarget, TSize.tapTarget), textStyle: text.labelLarge),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(TRadius.md), borderSide: BorderSide(color: cs.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(TRadius.md), borderSide: BorderSide(color: cs.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(TRadius.md), borderSide: BorderSide(color: cs.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(TRadius.md), borderSide: BorderSide(color: cs.error, width: 2)),
      hintStyle: text.bodyLarge!.copyWith(color: cs.onSurfaceVariant),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TRadius.sm)),
      side: BorderSide(color: cs.outlineVariant),
      backgroundColor: cs.surfaceContainerLowest,
      selectedColor: cs.primaryContainer,
      labelStyle: text.bodyMedium,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TRadius.md), side: BorderSide(color: cs.outlineVariant)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: TSize.navBar,
      backgroundColor: cs.surfaceContainerLowest,
      indicatorColor: cs.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cs.surfaceContainerLowest,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(TRadius.xl))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TRadius.xl)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.inverseSurface,
      contentTextStyle: text.bodyMedium!.copyWith(color: cs.onInverseSurface),
      actionTextColor: cs.inversePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TRadius.md)),
    ),
    dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 1),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ext.primaryFill,
      foregroundColor: cs.onPrimary,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? ext.primaryFill : cs.surfaceContainerHigh,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.transparent : cs.outline,
      ),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary),
  );
}

final ThemeData topildiLight = _build(_lightScheme, TopildiColors.light);
final ThemeData topildiDark = _build(_darkScheme, TopildiColors.dark);
