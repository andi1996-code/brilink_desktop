import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Utility class untuk menangani penyimpanan aplikasi dengan fallback
/// untuk mengatasi masalah OneDrive
class AppStorageManager {
  static const String appFolderName = 'BRILink';

  /// Mencoba berbagai lokasi untuk membuat folder aplikasi
  static Future<Directory> getAppDirectory() async {
    // Prioritas lokasi untuk mencoba membuat folder
    final locations = await _getPossibleLocations();

    for (final location in locations) {
      try {
        print('Trying location: ${location.path}');

        final appDir = Directory('${location.path}/$appFolderName');

        // Coba buat directory jika belum ada
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
          print('✅ Successfully created: ${appDir.path}');
        } else {
          print('✅ Directory already exists: ${appDir.path}');
        }

        // Test write permission dengan membuat file test
        final testFile = File('${appDir.path}/.test_write');
        try {
          await testFile.writeAsString('test');
          await testFile.delete();
          print('✅ Write permission OK');
          return appDir;
        } catch (e) {
          print('❌ No write permission: $e');
          continue;
        }
      } catch (e) {
        print('❌ Failed at ${location.path}: $e');
        continue;
      }
    }

    throw Exception('Could not create app directory in any location');
  }

  /// Mendapatkan daftar lokasi yang mungkin untuk folder aplikasi
  static Future<List<Directory>> _getPossibleLocations() async {
    final locations = <Directory>[];

    try {
      // 1. Coba Documents directory (default Flutter)
      final documentsDir = await getApplicationDocumentsDirectory();
      locations.add(documentsDir);
      print('Added Documents: ${documentsDir.path}');
    } catch (e) {
      print('Documents directory error: $e');
    }

    // 2. Coba %APPDATA%/Local
    final appDataLocal = Platform.environment['LOCALAPPDATA'];
    if (appDataLocal != null) {
      locations.add(Directory(appDataLocal));
      print('Added LOCALAPPDATA: $appDataLocal');
    }

    // 3. Coba %APPDATA%/Roaming
    final appDataRoaming = Platform.environment['APPDATA'];
    if (appDataRoaming != null) {
      locations.add(Directory(appDataRoaming));
      print('Added APPDATA: $appDataRoaming');
    }

    // 4. Coba %USERPROFILE%/Documents (bypass OneDrive redirect)
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null) {
      final localDocs = Directory('$userProfile/Documents');
      if (await localDocs.exists()) {
        locations.add(localDocs);
        print('Added Local Documents: ${localDocs.path}');
      }
    }

    // 5. Coba temp directory sebagai fallback terakhir
    try {
      final tempDir = await getTemporaryDirectory();
      locations.add(Directory('${tempDir.path}/Persistent'));
      print('Added Temp fallback: ${tempDir.path}/Persistent');
    } catch (e) {
      print('Temp directory error: $e');
    }

    // 6. Coba di folder aplikasi itu sendiri (portable mode)
    try {
      final currentDir = Directory.current;
      final portableDir = Directory('${currentDir.path}/AppData');
      locations.add(portableDir);
      print('Added Portable: ${portableDir.path}');
    } catch (e) {
      print('Portable directory error: $e');
    }

    return locations;
  }

  /// Mendapatkan file untuk session dengan fallback
  static Future<File> getSessionFile() async {
    final appDir = await getAppDirectory();
    return File('${appDir.path}/session.json');
  }

  /// Mendapatkan file untuk printer settings dengan fallback
  static Future<File> getPrinterSettingsFile() async {
    final appDir = await getAppDirectory();
    return File('${appDir.path}/printer_settings.json');
  }
}
