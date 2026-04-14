import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import '../../core/utils/web_downloader/web_downloader.dart';

class LocalStorageService {
  static const String _imagesDirName = 'product_images';

  /// Save an image directly to local storage (or SharedPreferences if Web)
  Future<void> saveProductImage(String imageId, XFile image, {bool isWeb = kIsWeb}) async {
    if (isWeb) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('img_$imageId', base64String);
      return;
    }

    final docDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docDir.path}/$_imagesDirName');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final bytes = await image.readAsBytes();
    final file = File('${imagesDir.path}/$imageId');
    await file.writeAsBytes(bytes);
  }

  /// Get image bytes (Base64 on Web, File on Native)
  Future<Uint8List?> getProductImageBytes(String imageId, {bool isWeb = kIsWeb}) async {
    if (isWeb) {
      final prefs = await SharedPreferences.getInstance();
      final base64String = prefs.getString('img_$imageId');
      if (base64String != null) {
        return base64Decode(base64String);
      }
      return null;
    }

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/$_imagesDirName/$imageId');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error reading image: $e');
    }
    return null;
  }
  
  /// Delete image
  Future<void> deleteProductImage(String imageId, {bool isWeb = kIsWeb}) async {
    if (isWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('img_$imageId');
      return;
    }
    final docDir = await getApplicationDocumentsDirectory();
    final file = File('${docDir.path}/$_imagesDirName/$imageId');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Export backup (Returns the path or triggers download on web)
  Future<String?> exportBackup() async {
    final archive = Archive();
    
    if (kIsWeb) {
      // Create backup from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('img_'));
      for (final key in keys) {
        final base64 = prefs.getString(key);
        if (base64 != null) {
          final bytes = base64Decode(base64);
          archive.addFile(ArchiveFile(key, bytes.length, bytes));
        }
      }
    } else {
      // Create backup from directory
      final docDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${docDir.path}/$_imagesDirName');
      if (await imagesDir.exists()) {
        final files = imagesDir.listSync();
        for (final file in files) {
          if (file is File) {
            final fileName = file.path.split(Platform.pathSeparator).last;
            final bytes = await file.readAsBytes();
            archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
          }
        }
      }
    }

    final zipData = ZipEncoder().encode(archive);
    // zipData is List<int> (not null in v4+)
    if (zipData.isEmpty) return null;

    if (kIsWeb) {
      await downloadWebFile('carbon_stores_images_backup.zip', zipData);
      return 'Downloaded backup to browser.'; 
    }

    // Pick save path
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Save Backup',
      fileName: 'carbon_stores_images_backup.zip',
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: Uint8List.fromList(zipData),
    );

    if (outputFile != null) {
      // On some platforms saveFile already writes the bytes if provided.
      // On Desktop, it might just return the path. 
      // To be safe, we check if the file exists/needs writing.
      if (!kIsWeb) {
        final file = File(outputFile);
        if (!await file.exists() || (await file.length() == 0)) {
          await file.writeAsBytes(zipData);
        }
      }
      return outputFile;
    }
    
    return null;
  }

  /// Import backup — returns a result with count and message for UI feedback.
  Future<ImportResult> importBackup() async {
    try {
      // Use FileType.any on mobile — FileType.custom with 'zip' is unreliable
      // on many Android file managers (SAF doesn't respect extension filters).
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return const ImportResult(count: 0, message: 'No file selected.');
      }

      final pickedFile = result.files.single;

      // Validate that user picked a zip file
      final fileName = pickedFile.name.toLowerCase();
      if (!fileName.endsWith('.zip')) {
        return ImportResult(
          count: 0,
          message: 'Please select a .zip file. Selected: ${pickedFile.name}',
          isError: true,
        );
      }

      Uint8List? bytes = pickedFile.bytes;

      // On Android, bytes may be null even with withData: true for large files.
      if (bytes == null && pickedFile.path != null) {
        try {
          bytes = await File(pickedFile.path!).readAsBytes();
        } catch (e) {
          debugPrint('[ImageImport] Failed to read from path: $e');
          return ImportResult(
            count: 0,
            message: 'Could not read file: $e',
            isError: true,
          );
        }
      }

      if (bytes == null || bytes.isEmpty) {
        return const ImportResult(
          count: 0,
          message: 'Selected file appears to be empty.',
          isError: true,
        );
      }

      debugPrint('[ImageImport] Read ${bytes.length} bytes from ${pickedFile.name}');

      final Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes);
      } catch (e) {
        return ImportResult(
          count: 0,
          message: 'Invalid zip file. Could not decode: $e',
          isError: true,
        );
      }

      debugPrint('[ImageImport] Archive contains ${archive.length} entries');

      if (archive.isEmpty) {
        return const ImportResult(count: 0, message: 'Zip file contains no images.');
      }

      int restoredCount = 0;

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        for (final file in archive) {
          if (file.isFile) {
            final data = file.content as List<int>;
            var key = file.name;
            if (!key.startsWith('img_')) {
              key = 'img_$key';
            }
            await prefs.setString(key, base64Encode(data));
            restoredCount++;
          }
        }
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${docDir.path}/$_imagesDirName');
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }

        for (final file in archive) {
          if (file.isFile) {
            final data = file.content as List<int>;
            var name = file.name;
            if (name.startsWith('img_')) {
              name = name.replaceFirst('img_', '');
            }
            if (name.contains('/')) {
              name = name.split('/').last;
            }
            if (name.isEmpty) continue;

            final localFile = File('${imagesDir.path}/$name');
            await localFile.writeAsBytes(data);
            debugPrint('[ImageImport] Restored: $name (${data.length} bytes)');
            restoredCount++;
          }
        }
      }

      debugPrint('[ImageImport] Total restored: $restoredCount');

      if (restoredCount == 0) {
        return const ImportResult(count: 0, message: 'Zip file had no image files to restore.');
      }

      return ImportResult(
        count: restoredCount,
        message: 'Successfully restored $restoredCount image${restoredCount == 1 ? '' : 's'}!',
      );
    } catch (e, stack) {
      debugPrint('[ImageImport] Error: $e');
      debugPrint('[ImageImport] Stack: $stack');
      return ImportResult(
        count: 0,
        message: 'Import failed: $e',
        isError: true,
      );
    }
  }
}

/// Result of an image import operation.
class ImportResult {
  final int count;
  final String message;
  final bool isError;

  const ImportResult({
    required this.count,
    required this.message,
    this.isError = false,
  });
}
