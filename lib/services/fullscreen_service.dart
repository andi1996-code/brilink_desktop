import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FullscreenService {
  static const String _fullscreenFileName = 'fullscreen_mode.txt';
  static const MethodChannel _channel = MethodChannel(
    'desktop_flutter_brilnik/fullscreen',
  );

  /// Get fullscreen preference file
  static Future<File> _getPreferenceFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/BRILink');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File('${appDir.path}/$_fullscreenFileName');
  }

  /// Get fullscreen preference
  static Future<bool> getFullscreenPreference() async {
    try {
      final file = await _getPreferenceFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return content.trim() == 'true';
      }
      return false; // Default: windowed
    } catch (e) {
      print("Error reading fullscreen preference: $e");
      return false;
    }
  }

  /// Set fullscreen preference
  static Future<void> setFullscreenPreference(bool isFullscreen) async {
    try {
      final file = await _getPreferenceFile();
      await file.writeAsString(isFullscreen ? 'true' : 'false');
    } catch (e) {
      print("Error saving fullscreen preference: $e");
    }
  }

  /// Enable fullscreen mode
  static Future<void> enableFullscreen() async {
    try {
      await _channel.invokeMethod('enableFullscreen');
    } on PlatformException catch (e) {
      print("Failed to enable fullscreen: ${e.message}");
    }
  }

  /// Disable fullscreen mode (show as normal window)
  static Future<void> disableFullscreen() async {
    try {
      await _channel.invokeMethod('disableFullscreen');
    } on PlatformException catch (e) {
      print("Failed to disable fullscreen: ${e.message}");
    }
  }

  /// Toggle fullscreen
  static Future<void> toggleFullscreen(bool enable) async {
    if (enable) {
      await enableFullscreen();
    } else {
      await disableFullscreen();
    }
    await setFullscreenPreference(enable);
  }
}
