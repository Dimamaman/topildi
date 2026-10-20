import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../di/injection.dart';
import '../media/photo_picker.dart';
import '../theme/topildi_theme.dart';

/// Asks camera vs gallery, then picks. Returns the local path or null.
Future<String?> pickPhoto(BuildContext context, {String title = 'Rasm qoʻshish'}) async {
  final source = await showModalBottomSheet<PhotoSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(TSpace.screen, 0, TSpace.screen, TSpace.xs),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          ListTile(
            minTileHeight: TSize.tapTarget,
            leading: const Icon(Symbols.photo_camera_rounded),
            title: const Text('Kamera'),
            onTap: () => Navigator.pop(ctx, PhotoSource.camera),
          ),
          ListTile(
            minTileHeight: TSize.tapTarget,
            leading: const Icon(Symbols.photo_library_rounded),
            title: const Text('Galereya'),
            onTap: () => Navigator.pop(ctx, PhotoSource.gallery),
          ),
          const SizedBox(height: TSpace.xs),
        ],
      ),
    ),
  );
  if (source == null) return null;
  return getIt<PhotoPicker>().pick(source);
}
