import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// App-wide light/dark choice (Tizim / Yorugʻ / Qorongʻi). In memory for now.
@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void set(ThemeMode mode) => emit(mode);
}
