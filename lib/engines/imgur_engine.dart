import 'dart:io';

import 'package:dio/dio.dart';

import '../configs/imgur_config.dart';
import '../core/error.dart';
import '../core/image_hosting_engine.dart';
import '../core/upload_result.dart';

// https://apidocs.imgur.com/#ee366f7c-69e6-46fd-bf26-e93303f64c84
class ImgurEngine extends ImageHostingEngine<ImgurConfig> {
  ImgurEngine(super.config);

  @override
  Future<UploadResult> uploadImage(File image,
      {ProgressCallback? onProgress}) async {
    if (!config.isAnonymous) {
      await _ensureValidAccessToken();
    }
    var filename = getTimestampedFilename(image.path);

    var formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: filename),
    });

    var headers = config.isAnonymous
        ? {'Authorization': 'Client-ID ${config.clientId}'}
        : {'Authorization': 'Bearer ${config.accessToken}'};

    var response = await dio.post(
      'https://api.imgur.com/3/image',
      data: formData,
      options: Options(headers: headers),
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      var data = jsonResponse['data'];
      return UploadResult(
        url: data['link'],
        deleteURL: config.isAnonymous
            ? ""
            : 'https://api.imgur.com/3/image/${data['deletehash']}',
        thumbnailURL: data['link'],
        filename: data['name'],
        imageSize: ImageSize(data['width'], data['height']),
        size: data['size'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(data['datetime'] * 1000),
      );
    } else {
      throw ImageHostingError(
          'Upload failed with status: ${response.statusCode}');
    }
  }

  @override
  Future<bool> deleteImage(UploadResult item) async {
    if (config.isAnonymous) {
      throw ImageHostingError(
          'Delete operation is not supported in anonymous mode');
    }
    await _ensureValidAccessToken();
    var response = await dio.delete(
      item.deleteURL,
      options:
          Options(headers: {'Authorization': 'Bearer ${config.accessToken}'}),
    );
    return response.statusCode == 200;
  }

  @override
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0}) async {
    if (config.isAnonymous) {
      throw ImageHostingError(
          'Getting uploaded images is not supported in anonymous mode');
    }
    await _ensureValidAccessToken();
    var response = await dio.get(
      'https://api.imgur.com/3/account/me/images/$offset',
      options:
          Options(headers: {'Authorization': 'Bearer ${config.accessToken}'}),
    );

    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      return (jsonResponse['data'] as List)
          .map((item) => UploadResult(
                url: item['link'],
                deleteURL:
                    'https://api.imgur.com/3/image/${item['deletehash']}',
                thumbnailURL: item['link'],
                filename: item['name'],
                imageSize: ImageSize(item['width'], item['height']),
                size: item['size'],
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                    item['datetime'] * 1000),
              ))
          .toList();
    } else {
      throw ImageHostingError(
          'Failed to get uploaded images with status: ${response.statusCode}');
    }
  }

  Future<void> _ensureValidAccessToken() async {
    if (config.accessToken == null || _isTokenExpired()) {
      await _refreshAccessToken();
    }
  }

  bool _isTokenExpired() {
    if (config.tokenExpirationTime == null) {
      return true;
    }
    return DateTime.now().isAfter(
        config.tokenExpirationTime!.subtract(const Duration(minutes: 5)));
  }

  Future<void> _refreshAccessToken() async {
    var response = await dio.post(
      'https://api.imgur.com/oauth2/token',
      data: {
        'client_id': config.clientId,
        'client_secret': config.clientSecret,
        'refresh_token': config.refreshToken,
        'grant_type': 'refresh_token',
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      config.updateToken(
        jsonResponse['access_token'],
        jsonResponse['refresh_token'],
        jsonResponse['expires_in'],
      );
    } else {
      throw ImageHostingError(
          'Failed to refresh token with status: ${response.statusCode}');
    }
  }
}
