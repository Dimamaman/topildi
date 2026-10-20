import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection.dart';
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
    return BlocProvider.value(
      value: getIt<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) => MaterialApp.router(
          title: 'Topildi',
          debugShowCheckedModeBanner: false,
          theme: topildiLight.withoutRipples(),
          darkTheme: topildiDark.withoutRipples(),
          themeMode: mode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
