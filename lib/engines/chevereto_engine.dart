import 'dart:io';

import 'package:dio/dio.dart';

import '../configs/chevereto_config.dart';
import '../core/error.dart';
import '../core/image_hosting_engine.dart';
import '../core/upload_result.dart';

class CheveretoEngine extends ImageHostingEngine<CheveretoConfig> {
  CheveretoEngine(super.config);

  @override
  Future<UploadResult> uploadImage(File image,
      {ProgressCallback? onProgress}) async {
    var filename = getTimestampedFilename(image.path);
    var formData = FormData.fromMap({
      'key': config.apiKey,
      'source': await MultipartFile.fromFile(image.path, filename: filename),
    });

    var response = await dio.post(
      config.apiUrl,
      data: formData,
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200) {
      var jsonResponse = response.data;

      if (jsonResponse['status_code'] == 200) {
        var data = jsonResponse['image'];
        return UploadResult(
          url: data['url'],
          deleteURL: data['delete_url'] ?? '',
          thumbnailURL: data['thumb']['url'],
          filename: data['filename'],
          imageSize: ImageSize(int.tryParse(data['width']) ?? 0,
              int.tryParse(data['height']) ?? 0),
          size: data['size'],
        );
      } else {
        throw ImageHostingError(
            'Upload failed: ${jsonResponse['status_text']}');
      }
    } else {
      throw ImageHostingError(
          'Upload failed: ${response.data['error']['message']}');
    }
  }

  @override
  Future<bool> deleteImage(UploadResult item) async {
    // Chevereto usually doesn't provide API-based deletion.
    // The deleteUrl is typically a web page for manual deletion.
    // We'll return false to indicate that automatic deletion is not supported.
    return false;
  }

  @override
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0}) async {
    // Chevereto API doesn't typically provide a way to list uploaded images.
    // This functionality might not be available unless your Chevereto instance has a custom API for this.
    throw UnimplementedError(
        'Listing uploaded images is not supported by the Chevereto API');
  }
}
