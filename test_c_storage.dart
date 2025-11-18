import 'dart:io';
import 'dart:convert';

/// Test script untuk C:\BRILink storage
void main() async {
  print('=== TEST C:\\BRILink STORAGE ===\n');

  try {
    const brilinkDir = 'C:\\BRILink';

    print('📂 Target Directory: $brilinkDir');

    // Create C:\BRILink directory
    final directory = Directory(brilinkDir);
    await directory.create(recursive: true);
    print('✅ Created C:\\BRILink directory');

    // Test write session file
    final sessionFile = File('$brilinkDir\\session.json');
    final sessionData = {
      'token': 'test_token_12345',
      'user': {'id': 1, 'name': 'Test User'},
      'baseUrl': 'https://test.example.com',
    };

    await sessionFile.writeAsString(jsonEncode(sessionData));
    print('✅ Created test session.json');

    // Test write printer settings file
    final printerFile = File('$brilinkDir\\printer_settings.json');
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

    // List all files in C:\BRILink directory
    print('\n📄 Files in C:\\BRILink:');
    final files = await directory.list().toList();
    for (var file in files) {
      if (file is File) {
        final stat = await file.stat();
        print('  • ${file.path.split('\\').last} (${stat.size} bytes)');
      }
    }

    print('\n✅ C:\\BRILink storage test completed successfully!');
    print('\nKelebihan menggunakan C:\\BRILink:');
    print('  ✅ Tidak terpengaruh OneDrive');
    print('  ✅ Path sederhana dan mudah diakses');
    print('  ✅ Tidak bergantung pada user profile');
    print('  ✅ Konsisten di semua komputer Windows');
  } catch (e, stackTrace) {
    print('❌ Error testing C:\\BRILink storage: $e');
    print('Stack trace: $stackTrace');

    // Jika gagal, mungkin perlu permission admin
    if (e.toString().contains('Access is denied') ||
        e.toString().contains('Permission denied')) {
      print('\n💡 Tips:');
      print('  • Jalankan aplikasi sebagai Administrator');
      print('  • Atau gunakan lokasi alternatif seperti:');
      print('    - C:\\Users\\[user]\\AppData\\Local\\BRILink');
      print('    - [executable_folder]\\data\\BRILink');
    }
  }
}
