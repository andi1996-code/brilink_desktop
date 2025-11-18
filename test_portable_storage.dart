import 'dart:io';
import 'dart:convert';

/// Test script untuk portable storage
void main() async {
  print('=== TEST PORTABLE STORAGE ===\n');

  try {
    // Get executable directory
    final executablePath = Platform.resolvedExecutable;
    final executableDir = File(executablePath).parent.path;

    print('📂 Executable Directory: $executableDir');

    // Create data/BRILink directory
    final dataDir = '$executableDir${Platform.pathSeparator}data';
    final brilinkDir = '$dataDir${Platform.pathSeparator}BRILink';

    print('📂 Data Directory: $dataDir');
    print('📂 BRILink Directory: $brilinkDir');

    // Create directories
    final brilinkDirectory = Directory(brilinkDir);
    await brilinkDirectory.create(recursive: true);
    print('✅ Created BRILink directory');

    // Test write session file
    final sessionFile = File(
      '$brilinkDir${Platform.pathSeparator}session.json',
    );
    final sessionData = {
      'token': 'test_token_12345',
      'user': {'id': 1, 'name': 'Test User'},
      'baseUrl': 'https://test.example.com',
    };

    await sessionFile.writeAsString(jsonEncode(sessionData));
    print('✅ Created test session.json');

    // Test write printer settings file
    final printerFile = File(
      '$brilinkDir${Platform.pathSeparator}printer_settings.json',
    );
    final printerData = {'printer_name': 'Test Printer POS58'};

    await printerFile.writeAsString(jsonEncode(printerData));
    print('✅ Created test printer_settings.json');

    // Verify files exist and readable
    if (await sessionFile.exists()) {
      final content = await sessionFile.readAsString();
      final data = jsonDecode(content);
      print('✅ Session file readable: ${data['user']['name']}');
    }

    if (await printerFile.exists()) {
      final content = await printerFile.readAsString();
      final data = jsonDecode(content);
      print('✅ Printer settings readable: ${data['printer_name']}');
    }

    // List all files in BRILink directory
    print('\n📄 Files in portable storage:');
    final files = await brilinkDirectory.list().toList();
    for (var file in files) {
      if (file is File) {
        final stat = await file.stat();
        print(
          '  • ${file.path.split(Platform.pathSeparator).last} (${stat.size} bytes)',
        );
      }
    }

    print('\n✅ Portable storage test completed successfully!');
    print('\nStructure created:');
    print('  📁 $executableDir');
    print('    📁 data/');
    print('      📁 BRILink/');
    print('        📄 session.json');
    print('        📄 printer_settings.json');
  } catch (e, stackTrace) {
    print('❌ Error testing portable storage: $e');
    print('Stack trace: $stackTrace');
  }
}
