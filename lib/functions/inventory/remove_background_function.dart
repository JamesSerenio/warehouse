import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../config/supabase_config.dart';
import '../../services/supabase_service.dart';

class RemoveBackgroundException implements Exception {
  const RemoveBackgroundException(this.message);
  final String message;
}

abstract final class RemoveBackgroundFunction {
  static Future<Uint8List> removeBackground({
    required Uint8List originalBytes,
    required String originalExtension,
  }) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        SupabaseConfig.backgroundRemovalFunctionName,
        body: {
          'image_base64': base64Encode(originalBytes),
          'input_extension': originalExtension.toLowerCase(),
          'output_format': 'png',
        },
      );

      if (response.status < 200 || response.status >= 300) {
        throw RemoveBackgroundException(
          'Background-removal service returned status ${response.status}.',
        );
      }

      final data = response.data;
      if (data is! Map) {
        throw const RemoveBackgroundException(
          'Background-removal service returned an invalid response.',
        );
      }
      final encodedImage = data['image_base64'];
      if (encodedImage is! String || encodedImage.isEmpty) {
        throw const RemoveBackgroundException(
          'Background-removal service returned no image.',
        );
      }

      final normalizedBase64 = encodedImage.contains(',')
          ? encodedImage.substring(encodedImage.indexOf(',') + 1)
          : encodedImage;
      final result = base64Decode(normalizedBase64);
      if (result.isEmpty) {
        throw const RemoveBackgroundException(
          'Background-removal service returned an empty image.',
        );
      }
      return result;
    } catch (error, stackTrace) {
      debugPrint('BACKGROUND REMOVAL ERROR: $error');
      debugPrint('$stackTrace');
      if (error is RemoveBackgroundException) rethrow;
      throw const RemoveBackgroundException(
        'Background removal failed. You can still use the original image.',
      );
    }
  }
}
