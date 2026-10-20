import 'package:flutter/material.dart';

extension NoRipple on ThemeData {
  /// Removes all tap feedback overlays: the Material ink ripple (splash) and InkWell tap highlight from
  /// every tappable widget — InkWell/InkResponse, buttons, IconButton, chips,
  /// ListTile, popup menus and Switch/Checkbox overlays — on all platforms.
  /// Buttons also lose their pressed/hover tint. Note: `XButton.styleFrom`
  /// with a `foregroundColor` derives its own tint and overrides the theme,
  /// so such calls must pass `overlayColor: Colors.transparent` too.
  ThemeData withoutRipples() {
    const none = WidgetStatePropertyAll<Color?>(Colors.transparent);
    ButtonStyle flat(ButtonStyle? s) => (s ?? const ButtonStyle()).copyWith(overlayColor: none);
    return copyWith(
      filledButtonTheme: FilledButtonThemeData(style: flat(filledButtonTheme.style)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: flat(outlinedButtonTheme.style)),
      textButtonTheme: TextButtonThemeData(style: flat(textButtonTheme.style)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: flat(elevatedButtonTheme.style)),
      iconButtonTheme: IconButtonThemeData(style: flat(iconButtonTheme.style)),
      menuButtonTheme: MenuButtonThemeData(style: flat(menuButtonTheme.style)),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      switchTheme: switchTheme.copyWith(overlayColor: none),
      checkboxTheme: checkboxTheme.copyWith(overlayColor: none),
      radioTheme: radioTheme.copyWith(overlayColor: none),
    );
  }
}
