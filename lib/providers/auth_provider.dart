import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/portable_storage.dart';

/// AuthProvider handles authentication state and login API.
class AuthProvider extends ChangeNotifier {
  final ApiService apiService;

  bool isLoading = false;
  String? error;
  Map<String, dynamic>? user;
  String? token;
  String? lastUsedBaseUrl;

  // Track if session is fully loaded
  Future<void>? _sessionLoadFuture;

  AuthProvider({ApiService? service})
    : apiService = service ?? ApiService(baseUrl: 'temp://placeholder') {
    _sessionLoadFuture = _initializeStorage();
  }

  /// Wait for session to be fully loaded
  Future<void> ensureSessionLoaded() async {
    if (_sessionLoadFuture != null) {
      await _sessionLoadFuture!;
    }
  }

  /// Initialize storage dengan migrasi otomatis
  Future<void> _initializeStorage() async {
    try {
      // Cek apakah portable storage bisa digunakan
      final canWrite = await PortableStorage.testWritePermission();
      debugPrint('Portable storage writable: $canWrite');

      if (canWrite) {
        // Coba migrasi data dari Documents jika ada
        final migrated = await PortableStorage.migrateFromDocuments();
        if (migrated) {
          debugPrint('Successfully migrated data to portable storage');
        }
      }

      // Load session setelah storage ready
      await _loadSession();
    } catch (e) {
      debugPrint('Storage initialization error: $e');
      // Tetap load session meski ada error
      await _loadSession();
    }
  }

  /// Returns file for storing session data - menggunakan portable storage
  Future<File> _getSessionFile() async {
    try {
      // Coba gunakan portable storage (di samping executable)
      final sessionPath = await PortableStorage.getSessionFilePath();
      return File(sessionPath);
    } catch (e) {
      // Fallback ke Documents jika portable storage gagal
      debugPrint('Fallback to Documents storage: $e');
      final directory = await getApplicationDocumentsDirectory();
      final appDir = Directory('${directory.path}/BRILink');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return File('${appDir.path}/session.json');
    }
  }

  /// Load session from file
  Future<void> _loadSession() async {
    try {
      final file = await _getSessionFile();

      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        token = data['token'] as String?;
        user = (data['user'] as Map?)?.cast<String, dynamic>();
        lastUsedBaseUrl = data['baseUrl'] as String?;

        // Update ApiService dengan base URL yang tersimpan
        if (lastUsedBaseUrl != null) {
          apiService.updateBaseUrl(lastUsedBaseUrl!);
        }
      }
    } catch (e) {
      // Silent error handling
    }
    // Notify listeners after loading session to update UI
    notifyListeners();
  }

  /// Perform login and save session to file
  Future<bool> login(String username, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await apiService.login(username, password);
      final data = response.data as Map<String, dynamic>;

      // New API structure: { success: true, data: { token: '...', user: {...} }, message: '...' }
      if (data['success'] == true && data['data'] is Map) {
        final loginData = data['data'] as Map<String, dynamic>;
        token = loginData['token'] as String;
        user = (loginData['user'] as Map?)?.cast<String, dynamic>();
        // Save to file
        await _saveSession();
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = data['message'] as String? ?? 'Login failed';
      }
    } on DioError catch (e) {
      error = e.response?.data['message'] ?? e.message;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  /// Perform login with custom server URL
  Future<bool> loginWithCustomUrl(
    String username,
    String password,
    String baseUrl,
  ) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final customApiService = ApiService(baseUrl: baseUrl);
      final response = await customApiService.login(username, password);
      final data = response.data as Map<String, dynamic>;

      // New API structure: { success: true, data: { token: '...', user: {...} }, message: '...' }
      if (data['success'] == true && data['data'] is Map) {
        final loginData = data['data'] as Map<String, dynamic>;
        token = loginData['token'] as String;
        user = (loginData['user'] as Map?)?.cast<String, dynamic>();
        lastUsedBaseUrl = baseUrl;
        // Update the main apiService with the new base URL
        apiService.updateBaseUrl(baseUrl);
        // Save to file
        await _saveSession();
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        error = data['message'] as String? ?? 'Login failed';
      }
    } on DioError catch (e) {
      error = e.response?.data['message'] ?? e.message;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  /// Update and persist last used base URL (useful before login)
  Future<void> setLastUsedBaseUrl(String url) async {
    lastUsedBaseUrl = url;
    try {
      apiService.updateBaseUrl(url);
    } catch (_) {}
    await _saveSession();
    notifyListeners();
  }

  /// Save session data to file
  Future<void> _saveSession() async {
    final file = await _getSessionFile();
    final data = {'token': token, 'user': user, 'baseUrl': lastUsedBaseUrl};
    await file.writeAsString(jsonEncode(data));
  }

  /// Clear session file on logout
  Future<void> logout() async {
    // attempt server-side logout if we have a token
    isLoading = true;
    notifyListeners();
    try {
      if (token != null && token!.isNotEmpty) {
        await apiService.logout(token: token);
      }
    } catch (e) {
      // ignore network errors but log for debugging
      debugPrint('Error during server logout: $e');
    }

    // Clear local session regardless of server response
    user = null;
    token = null;
    // Preserve lastUsedBaseUrl so the user doesn't need to re-enter server URL
    try {
      await _saveSession();
    } catch (e) {
      // If saving fails for some reason, attempt to persist only the baseUrl
      try {
        if (lastUsedBaseUrl != null) {
          final file = await _getSessionFile();
          final data = {'baseUrl': lastUsedBaseUrl};
          await file.writeAsString(jsonEncode(data));
        }
      } catch (_) {}
    }

    isLoading = false;
    notifyListeners();
  }
}
