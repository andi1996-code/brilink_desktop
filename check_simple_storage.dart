import 'dart:io';

void main() async {
  // Mengecek environment variables untuk Documents directory
  final userProfile = Platform.environment['USERPROFILE'];

  if (userProfile != null) {
    print('User Profile: $userProfile');

    // Path Documents biasanya di USERPROFILE/Documents
    final documentsPath = '$userProfile\\Documents';
    final documentsDir = Directory(documentsPath);

    print('Documents Directory: $documentsPath');
    print('Documents Directory exists: ${await documentsDir.exists()}');

    // Check BRILink directory
    final brilinkPath = '$documentsPath\\BRILink';
    final brilinkDir = Directory(brilinkPath);

    print('BRILink Directory: $brilinkPath');
    print('BRILink Directory exists: ${await brilinkDir.exists()}');

    if (await brilinkDir.exists()) {
      print('\nIsi folder BRILink:');
      try {
        final files = await brilinkDir.list().toList();
        for (var file in files) {
          if (file is File) {
            final stat = await file.stat();
            print(
              '  📄 ${file.path.split('\\').last} (${stat.size} bytes) - Modified: ${stat.modified}',
            );
          } else if (file is Directory) {
            print('  📁 ${file.path.split('\\').last}/');
          }
        }

        // Check isi file session.json dan printer_settings.json
        final sessionFile = File('$brilinkPath\\session.json');
        final printerFile = File('$brilinkPath\\printer_settings.json');

        if (await sessionFile.exists()) {
          print('\n📄 session.json content:');
          print(await sessionFile.readAsString());
        }

        if (await printerFile.exists()) {
          print('\n📄 printer_settings.json content:');
          print(await printerFile.readAsString());
        }
      } catch (e) {
        print('Error reading BRILink directory: $e');
      }
    }
  } else {
    print('USERPROFILE environment variable tidak ditemukan');
  }
}
