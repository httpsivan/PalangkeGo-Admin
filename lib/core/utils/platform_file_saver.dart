import 'dart:typed_data';

import 'platform_file_saver_stub.dart'
    if (dart.library.html) 'platform_file_saver_web.dart'
    if (dart.library.io) 'platform_file_saver_desktop.dart' as saver;

Future<void> saveFileBytes({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) =>
    saver.saveFileBytes(bytes: bytes, filename: filename, mimeType: mimeType);
