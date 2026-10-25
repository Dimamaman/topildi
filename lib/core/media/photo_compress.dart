import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Re-encodes a local photo for upload: at most 1600px, JPEG 82, and no
/// EXIF (drops GPS and camera data before anything leaves the phone).
Future<Uint8List> compressForUpload(String path) async {
  final bytes = await FlutterImageCompress.compressWithFile(
    path,
    minWidth: 1600,
    minHeight: 1600,
    quality: 82,
    keepExif: false,
    format: CompressFormat.jpeg,
  );
  return bytes ?? await File(path).readAsBytes();
}
