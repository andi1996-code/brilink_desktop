import 'dart:io';

/// Utility untuk mengelola storage yang sederhana (langsung di C:\BRILink)
/// Menghindari masalah OneDrive dan permission Documents folder
class PortableStorage {
  /// Mendapatkan direktori BRILink langsung di C:
  static String getBRILinkDirectory() {
    return 'C:${Platform.pathSeparator}BRILink';
  }

  /// Pastikan direktori BRILink ada, buat jika belum ada
  static Future<Directory> ensureBRILinkDirectory() async {
    final brilinkPath = getBRILinkDirectory();
    final brilinkDir = Directory(brilinkPath);

    if (!await brilinkDir.exists()) {
      await brilinkDir.create(recursive: true);
    }

    return brilinkDir;
  }

  /// Mendapatkan path lengkap untuk file session
  static Future<String> getSessionFilePath() async {
    await ensureBRILinkDirectory();
    final brilinkDir = getBRILinkDirectory();
    return '$brilinkDir${Platform.pathSeparator}session.json';
  }

  /// Mendapatkan path lengkap untuk file printer settings
  static Future<String> getPrinterSettingsFilePath() async {
    await ensureBRILinkDirectory();
    final brilinkDir = getBRILinkDirectory();
    return '$brilinkDir${Platform.pathSeparator}printer_settings.json';
  }

  /// Test apakah bisa menulis ke direktori C:\BRILink
  static Future<bool> testWritePermission() async {
    try {
      await ensureBRILinkDirectory();
      final testFile = File(
        '${getBRILinkDirectory()}${Platform.pathSeparator}test_write.tmp',
      );
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Migrasi data dari lokasi lama (Documents) ke C:\BRILink
  static Future<bool> migrateFromDocuments() async {
    try {
      // Coba baca dari lokasi Documents lama
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile == null) return false;

      final oldBrilinkDir = Directory(
        '$userProfile${Platform.pathSeparator}Documents${Platform.pathSeparator}BRILink',
      );
      if (!await oldBrilinkDir.exists()) return false;

      // Pastikan direktori baru ada
      await ensureBRILinkDirectory();
      final newBrilinkDir = getBRILinkDirectory();

      // Copy semua file dari lokasi lama ke baru
      final files = await oldBrilinkDir.list().toList();
      for (var file in files) {
        if (file is File) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          final newFilePath =
              '$newBrilinkDir${Platform.pathSeparator}$fileName';
          await file.copy(newFilePath);
        }
      }

      return true;
    } catch (e) {
      print('Error during migration: $e');
      return false;
    }
  }

  /// Info untuk debugging
  static Future<Map<String, dynamic>> getStorageInfo() async {
    final brilinkDir = getBRILinkDirectory();

    return {
      'brilink_directory': brilinkDir,
      'brilink_dir_exists': await Directory(brilinkDir).exists(),
      'write_permission': await testWritePermission(),
    };
  }
}
