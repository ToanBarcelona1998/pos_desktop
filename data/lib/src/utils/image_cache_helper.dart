import 'dart:io';

import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Helper class for downloading and caching images
class ImageCacheHelper {
  /// Downloads an image from a URL and saves it to the cache directory
  /// Returns the local file path if successful, null otherwise
  static Future<String?> downloadAndCacheImage({
    required String imageUrl,
    required String cacheSubdirectory,
    String? fileName,
  }) async {
    try {
      // Validate URL
      final uri = Uri.tryParse(imageUrl);
      if (imageUrl.isEmpty || uri == null || !uri.hasAbsolutePath) {
        Logger.logI('Invalid image URL: $imageUrl');
        return null;
      }

      // Get cache directory
      final Directory cacheDir = await getApplicationDocumentsDirectory();
      final Directory imageCacheDir = Directory(
        path.join(cacheDir.path, 'payment_account_images', cacheSubdirectory),
      );

      // Create directory if it doesn't exist
      if (!await imageCacheDir.exists()) {
        await imageCacheDir.create(recursive: true);
      }

      // Generate filename if not provided
      final String finalFileName = fileName ??
          path.basename(Uri.parse(imageUrl).path) ??
          '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final File localFile = File(path.join(imageCacheDir.path, finalFileName));

      // Check if file already exists
      if (await localFile.exists()) {
        Logger.logI('Image already cached: ${localFile.path}');
        return localFile.path;
      }

      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        Logger.logE('Failed to download image: ${response.statusCode}');
        return null;
      }

      // Save to local file
      await localFile.writeAsBytes(response.bodyBytes);
      Logger.logI('Image cached successfully: ${localFile.path}');

      return localFile.path;
    } catch (e) {
      Logger.logE('Error downloading and caching image: $imageUrl', e);
      return null;
    }
  }

  /// Clears all cached images in the specified subdirectory
  static Future<void> clearCache({
    required String cacheSubdirectory,
  }) async {
    try {
      final Directory cacheDir = await getApplicationDocumentsDirectory();
      final Directory imageCacheDir = Directory(
        path.join(cacheDir.path, 'payment_account_images', cacheSubdirectory),
      );

      if (!await imageCacheDir.exists()) {
        Logger.logI('Cache directory does not exist: ${imageCacheDir.path}');
        return;
      }

      final List<FileSystemEntity> files = imageCacheDir.listSync();
      int deletedCount = 0;

      for (final file in files) {
        if (file is File) {
          try {
            await file.delete();
            deletedCount++;
            Logger.logI('Deleted cached image: ${file.path}');
          } catch (e) {
            Logger.logE('Error deleting cached image: ${file.path}', e);
          }
        }
      }

      Logger.logI('Cleared cache: $deletedCount files deleted from $cacheSubdirectory');
    } catch (e) {
      Logger.logE('Error clearing cache', e);
    }
  }
}

