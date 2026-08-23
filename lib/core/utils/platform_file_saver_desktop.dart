import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<void> saveFileBytes({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  final extension = filename.contains('.') ? filename.split('.').last : null;
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save $filename',
    fileName: filename,
    type: extension != null ? FileType.custom : FileType.any,
    allowedExtensions: extension != null ? [extension] : null,
  );
  if (path != null && path.isNotEmpty) {
    final file = File(path);
    await file.writeAsBytes(bytes);
  }
}
