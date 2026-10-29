import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
import '../core/l10n/app_language.dart';
import '../core/l10n/language_cubit.dart';
import '../core/theme/no_ripple.dart';
import '../core/theme/theme_cubit.dart';

import '../core/theme/topildi_theme.dart';
import 'router.dart';
import 'routes.dart';

class TopildiApp extends StatefulWidget {
  const TopildiApp({super.key, this.initialLocation = Routes.splash});

  /// Tests start deeper in the app (e.g. the feed).
  final String initialLocation;

  @override
  State<TopildiApp> createState() => _TopildiAppState();
}

class _TopildiAppState extends State<TopildiApp> {
  late final GoRouter _router = createRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider.value(value: getIt<LanguageCubit>()),
      ],
      child: Builder(
        builder: (context) {
          final mode = context.watch<ThemeCubit>().state;
          final language = context.watch<LanguageCubit>().state;
          return MaterialApp.router(
            title: 'Topildi',
            debugShowCheckedModeBanner: false,
            theme: topildiLight.withoutRipples(),
            darkTheme: topildiDark.withoutRipples(),
            themeMode: mode,
            locale: language.materialLocale,
            supportedLocales: [for (final l in AppLanguage.values) l.materialLocale],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            scrollBehavior: const _AppScrollBehavior(),
            // iOS-style keyboard: a tap on anything that is not a control
            // (text, background, a message) closes it. Buttons and fields
            // win the tap, so they keep working with the keyboard open.
            builder: (context, child) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

/// Dragging any scroll view closes the keyboard, as on iOS.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollViewKeyboardDismissBehavior getKeyboardDismissBehavior(BuildContext context) =>
      ScrollViewKeyboardDismissBehavior.onDrag;
}
