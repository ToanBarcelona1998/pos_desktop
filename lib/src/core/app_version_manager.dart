import 'dart:io';
import 'package:domain/domain.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app version and handles cache/database clearing on version updates
class AppVersionManager {
  static const String _versionKey = 'app_version';
  static const String _appVersion = '1.0.3'; // Update this when releasing new version

  /// Checks if app version has changed and clears cache/database if needed
  static Future<void> checkAndHandleVersionUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedVersion = prefs.getString(_versionKey);
      
      // Get current version from package info
      
      // If no stored version or version changed, clear cache and database
      if (storedVersion == null || _isVersionNewer(_appVersion, storedVersion)) {
        Logger.logI('App version updated from $storedVersion to $_appVersion. Clearing cache and database...');
        
        // Clear shared preferences (languages, theme, etc.)
        await _clearSharedPreferences(prefs);
        
        // Clear database
        await _clearDatabase();
        
        // Save new version
        await prefs.setString(_versionKey, _appVersion);

        Logger.logI('Cache and database cleared successfully.');
      } else {
        // Update version even if same (in case of reinstall)
        await prefs.setString(_versionKey, _appVersion);
      }
    } catch (e) {
      Logger.logE('Error checking app version', e);
      // Continue app initialization even if version check fails
    }
  }

  /// Compares two version strings (e.g., "1.0.1" vs "1.0.0")
  /// Returns true if version1 is newer than version2
  static bool _isVersionNewer(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();
      
      // Pad with zeros if needed
      while (v1Parts.length < v2Parts.length) {
        v1Parts.add(0);
      }
      while (v2Parts.length < v1Parts.length) {
        v2Parts.add(0);
      }
      
      for (int i = 0; i < v1Parts.length; i++) {
        if (v1Parts[i] > v2Parts[i]) return true;
        if (v1Parts[i] < v2Parts[i]) return false;
      }
      
      return false; // Versions are equal
    } catch (e) {
      return false;
    }
  }

  /// Clears shared preferences (languages, theme, etc.)
  static Future<void> _clearSharedPreferences(SharedPreferences prefs) async {
    try {
      // Get all keys
      final keys = prefs.getKeys();
      
      // Remove all keys except version (we'll set it after)
      for (final key in keys) {
        if (key != _versionKey) {
          await prefs.remove(key);
        }
      }
      Logger.logI('Shared preferences cleared successfully.');
    } catch (e) {
      Logger.logE('Error clearing shared preferences', e);
    }
  }

  /// Clears the database by deleting database files
  static Future<void> _clearDatabase() async {
    try {
      final Directory documentsDirectory = await getApplicationDocumentsDirectory();
      final String documentsPath = documentsDirectory.path;
      
      // Delete all PosDemo*.db files (for different user IDs)
      final dir = Directory(documentsPath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.contains('PosDemo') && entity.path.endsWith('.db')) {
            try {
              await entity.delete();
              Logger.logI('Deleted database file: ${entity.path}');
            } catch (e) {
              Logger.logI('Error deleting database file ${entity.path}: $e');
            }
          }
        }
      }
      Logger.logI('Database files cleared successfully.');
    } catch (e) {
      Logger.logE('Error clearing database', e);
    }
  }
}

