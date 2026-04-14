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

  /// Import backup
  Future<int> importBackup() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true, // Required for Web
    );

    if (result != null && (result.files.single.path != null || result.files.single.bytes != null)) {
      final bytes = result.files.single.bytes ?? await File(result.files.single.path!).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      int restoredCount = 0;

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        for (final file in archive) {
          if (file.isFile) {
            final data = file.content as List<int>;
            await prefs.setString(file.name, base64Encode(data));
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
            // Adjust prefix for compatibility
            var fileName = file.name;
            if (fileName.startsWith('img_')) {
              fileName = fileName.replaceFirst('img_', '');
            }
            final localFile = File('${imagesDir.path}/$fileName');
            await localFile.writeAsBytes(data);
            restoredCount++;
          }
        }
      }
      return restoredCount;
    }
    return 0;
  }
}
