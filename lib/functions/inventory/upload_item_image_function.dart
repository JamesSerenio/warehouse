import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

class UploadItemImageException implements Exception {
  const UploadItemImageException(this.message);
  final String message;
}

abstract final class UploadItemImageFunction {
  static const _bucket = 'item-images';

  static Future<String> uploadItemImage({
    required Object itemId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final normalizedExtension = extension.toLowerCase().replaceFirst('.', '');
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(normalizedExtension)) {
      throw const UploadItemImageException(
        'Please select a JPG, PNG, or WEBP image.',
      );
    }
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw const UploadItemImageException('Image must be 5 MB or smaller.');
    }

    final path = '${itemId.toString()}/product.$normalizedExtension';
    var uploaded = false;
    try {
      await SupabaseService.client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentType(normalizedExtension),
            ),
          );
      uploaded = true;
      final updatedItem = await SupabaseService.client
          .from('items')
          .update({'image_path': path})
          .eq('id', itemId)
          .select('image_path')
          .single();
      if (updatedItem['image_path'] != path) {
        throw const UploadItemImageException(
          'The uploaded image path could not be saved.',
        );
      }
      return path;
    } catch (error, stackTrace) {
      debugPrint('ITEM IMAGE UPLOAD ERROR: $error');
      debugPrint('$stackTrace');
      if (uploaded) {
        try {
          await SupabaseService.client.storage.from(_bucket).remove([path]);
        } catch (cleanupError, cleanupStackTrace) {
          debugPrint('ITEM IMAGE CLEANUP ERROR: $cleanupError');
          debugPrint('$cleanupStackTrace');
        }
      }
      throw const UploadItemImageException(
        'Item was added, but the image could not be uploaded.',
      );
    }
  }

  static String _contentType(String extension) => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
