import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Compresses invoice/attachment images before upload (same quality targets as gallery pick).
class ImageCompressUtil {
  ImageCompressUtil._();

  static const int defaultQuality = 85;
  static const int defaultMaxDimension = 1920;

  static bool _isCompressibleImage(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.jpg' ||
        ext == '.jpeg' ||
        ext == '.png' ||
        ext == '.heic' ||
        ext == '.heif' ||
        ext.isEmpty;
  }

  /// Returns a compressed copy in temp storage, or the original file on failure.
  static Future<File> compressForUpload(File file) async {
    if (!await file.exists()) return file;
    if (!_isCompressibleImage(file.path)) return file;

    final originalLength = await file.length();
    // Skip tiny files — already small enough.
    if (originalLength > 0 && originalLength < 200 * 1024) return file;

    final dir = await getTemporaryDirectory();
    final ext = p.extension(file.path);
    final outExt = ext.isNotEmpty ? ext : '.jpg';
    final targetPath = p.join(
      dir.path,
      'upload_${DateTime.now().microsecondsSinceEpoch}$outExt',
    );

    try {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: defaultQuality,
        minWidth: defaultMaxDimension,
        minHeight: defaultMaxDimension,
        format: outExt == '.png'
            ? CompressFormat.png
            : CompressFormat.jpeg,
      );
      if (compressed == null) return file;
      final out = File(compressed.path);
      if (!await out.exists()) return file;
      final compressedLength = await out.length();
      if (compressedLength <= 0 || compressedLength >= originalLength) {
        return file;
      }
      return out;
    } catch (_) {
      return file;
    }
  }

  static Future<List<File>> compressAllForUpload(List<File> files) async {
    if (files.isEmpty) return const [];
    final out = <File>[];
    for (final file in files) {
      out.add(await compressForUpload(file));
    }
    return out;
  }
}
