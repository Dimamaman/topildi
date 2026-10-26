import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../di/injection.dart';
import '../media/photo_picker.dart';
import '../l10n/tr.dart';
import 'pull_down_menu.dart';

/// Asks camera vs gallery in a glass pull-down under [anchor], then picks.
/// Returns the local path or null.
Future<String?> pickPhoto(BuildContext context, {required BuildContext anchor, String? title}) async {
  final source = await showPullDownMenu(
    context,
    anchor: anchor,
    label: title ?? tr('Rasm qoʻshish'),
    items: [(PhotoSource.camera, tr('Kamera')), (PhotoSource.gallery, tr('Galereya'))],
    icons: const {0: Symbols.photo_camera_rounded, 1: Symbols.photo_library_rounded},
  );
  if (source == null) return null;
  return getIt<PhotoPicker>().pick(source);
}
