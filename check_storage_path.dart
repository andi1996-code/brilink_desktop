import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  print('=== DIAGNOSTIC ONEDRIVE & STORAGE ISSUES ===\n');

  // 1. Check environment variables
  print('🔍 Environment Variables:');
  print('  USERPROFILE: ${Platform.environment['USERPROFILE']}');
  print('  LOCALAPPDATA: ${Platform.environment['LOCALAPPDATA']}');
  print('  APPDATA: ${Platform.environment['APPDATA']}');
  print('  OneDrive: ${Platform.environment['OneDrive']}');
  print('  OneDriveConsumer: ${Platform.environment['OneDriveConsumer']}');
  print('  OneDriveCommercial: ${Platform.environment['OneDriveCommercial']}');

  // 2. Check Flutter's getApplicationDocumentsDirectory
  try {
    print('\n📂 Flutter Documents Directory:');
    final directory = await getApplicationDocumentsDirectory();
    print('  Path: ${directory.path}');
    print('  Exists: ${await directory.exists()}');

    // Check if it's OneDrive redirect
    if (directory.path.toLowerCase().contains('onedrive')) {
      print('  ⚠️  WARNING: OneDrive redirect detected!');
    }

    // Try to create test folder
    try {
      final testDir = Directory('${directory.path}/BRILink_Test');
      await testDir.create(recursive: true);
      print('  ✅ Can create directories');

      // Test write permission
      final testFile = File('${testDir.path}/test.txt');
      await testFile.writeAsString('test write permission');
      print('  ✅ Can write files');

      // Cleanup
      await testDir.delete(recursive: true);
      print('  ✅ Can delete files');
    } catch (e) {
      print('  ❌ Permission error: $e');
    }
  } catch (e) {
    print('\n❌ Flutter Documents Directory error: $e');
  }

  // 3. Check alternative locations
  print('\n📂 Alternative Storage Locations:');

  // Local Documents (bypass OneDrive)
  final userProfile = Platform.environment['USERPROFILE'];
  if (userProfile != null) {
    final localDocs = Directory('$userProfile/Documents');
    print('  Local Documents: ${localDocs.path}');
    print('    Exists: ${await localDocs.exists()}');

    if (await localDocs.exists()) {
      try {
        final testDir = Directory('${localDocs.path}/BRILink_Test');
        await testDir.create(recursive: true);
        final testFile = File('${testDir.path}/test.txt');
        await testFile.writeAsString('test');
        await testDir.delete(recursive: true);
        print('    ✅ Writable');
      } catch (e) {
        print('    ❌ Not writable: $e');
      }
    }
  }

  // LOCALAPPDATA
  final localAppData = Platform.environment['LOCALAPPDATA'];
  if (localAppData != null) {
    final localAppDir = Directory(localAppData);
    print('  LocalAppData: ${localAppDir.path}');
    print('    Exists: ${await localAppDir.exists()}');

    if (await localAppDir.exists()) {
      try {
        final testDir = Directory('${localAppDir.path}/BRILink_Test');
        await testDir.create(recursive: true);
        final testFile = File('${testDir.path}/test.txt');
        await testFile.writeAsString('test');
        await testDir.delete(recursive: true);
        print('    ✅ Writable');
      } catch (e) {
        print('    ❌ Not writable: $e');
      }
    }
  }

  // APPDATA
  final appData = Platform.environment['APPDATA'];
  if (appData != null) {
    final appDataDir = Directory(appData);
    print('  AppData: ${appDataDir.path}');
    print('    Exists: ${await appDataDir.exists()}');

    if (await appDataDir.exists()) {
      try {
        final testDir = Directory('${appDataDir.path}/BRILink_Test');
        await testDir.create(recursive: true);
        final testFile = File('${testDir.path}/test.txt');
        await testFile.writeAsString('test');
        await testDir.delete(recursive: true);
        print('    ✅ Writable');
      } catch (e) {
        print('    ❌ Not writable: $e');
      }
    }
  }

  // 4. Check existing BRILink folder
  print('\n📂 Existing BRILink Directory:');
  try {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/BRILink');
    print('  Path: ${appDir.path}');
    print('  Exists: ${await appDir.exists()}');

    if (await appDir.exists()) {
      final files = await appDir.list().toList();
      print('  Files count: ${files.length}');
      for (var file in files) {
        if (file is File) {
          print(
            '    📄 ${file.path.split('\\').last} (${await file.length()} bytes)',
          );
        } else if (file is Directory) {
          print('    📁 ${file.path.split('\\').last}/');
        }
      }
    }
  } catch (e) {
    print('  ❌ Error checking BRILink: $e');
  }

  print('\n=== RECOMMENDATIONS ===');
  print('1. If OneDrive redirect detected, use LOCALAPPDATA or APPDATA');
  print('2. Implement fallback mechanism for storage locations');
  print('3. Add proper error handling for folder creation');
  print('4. Consider portable mode (store in app directory)');
}
