import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../storage/stores.dart';
import 'app_language.dart';

/// Interface language (Oʻzbekcha / Ўзбекча / Русский), persisted.
/// Changing it updates [AppLanguage.current] and rebuilds every widget,
/// so all [tr] calls pick up the new language in place (no restart, no
/// lost screen state).
@lazySingleton
class LanguageCubit extends Cubit<AppLanguage> {
  LanguageCubit(this._kv) : super(_read(_kv)) {
    AppLanguage.current = state;
  }

  final KeyValueStore _kv;

  static AppLanguage _read(KeyValueStore kv) => AppLanguage.fromCode(kv.getString(StoreKeys.language));

  void set(AppLanguage language) {
    if (language == state) return;
    AppLanguage.current = language;
    _kv.setString(StoreKeys.language, language.code);
    emit(language);
    _rebuildAll();
  }

  static void _rebuildAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }
}
