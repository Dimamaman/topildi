import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../storage/stores.dart';

/// App-wide light/dark choice (Tizim / Yorugʻ / Qorongʻi), persisted.
@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._kv) : super(_read(_kv));

  final KeyValueStore _kv;

  static ThemeMode _read(KeyValueStore kv) =>
      ThemeMode.values.asNameMap()[kv.getString(StoreKeys.themeMode)] ?? ThemeMode.system;

  void set(ThemeMode mode) {
    emit(mode);
    _kv.setString(StoreKeys.themeMode, mode.name);
  }
}
