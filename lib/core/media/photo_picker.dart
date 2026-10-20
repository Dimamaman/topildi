import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import 'app_dirs.dart';

enum PhotoSource { camera, gallery }

abstract interface class PhotoPicker {
  /// Local file path of the picked photo, or null if cancelled/failed.
  /// Photos are downscaled and picked without full metadata so EXIF (incl.
  /// GPS) is not requested; the backend must still strip EXIF on upload.
  Future<String?> pick(PhotoSource source);
}

@prod
@LazySingleton(as: PhotoPicker)
class DevicePhotoPicker implements PhotoPicker {
  DevicePhotoPicker(this._dirs);

  final AppDirs _dirs;
  final _picker = ImagePicker();

  @override
  Future<String?> pick(PhotoSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (file == null) return null;
      // image_picker writes to a temp/cache dir the OS may purge; keep a copy.
      final dir = Directory(_dirs.photos);
      await dir.create(recursive: true);
      final ext = file.path.contains('.')
          ? file.path.substring(file.path.lastIndexOf('.'))
          : '.jpg';
      final saved = await File(
        file.path,
      ).copy('${dir.path}/${DateTime.now().microsecondsSinceEpoch}$ext');
      return saved.path;
    } catch (_) {
      // Camera unavailable (simulator) or permission denied.
      return null;
    }
  }
}

@test
@LazySingleton(as: PhotoPicker)
class FakePhotoPicker implements PhotoPicker {
  int _n = 0;

  @override
  Future<String?> pick(PhotoSource source) async => 'test://photo/${_n++}';
}
