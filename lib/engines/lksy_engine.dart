import 'dart:io';
import 'package:dio/dio.dart';

import '../configs/lsky_config.dart';
import '../core/error.dart';
import '../core/image_hosting_engine.dart';
import '../core/upload_result.dart';

class LskyEngine extends ImageHostingEngine<LskyConfig> {
  LskyEngine(super.config);

  @override
  Future<UploadResult> uploadImage(File image,
      {ProgressCallback? onProgress}) async {
    var formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path),
      if (config.albumId != null) 'album_id': config.albumId,
      if (config.strategyId != null) 'strategy_id': config.strategyId,
    });

    var response = await dio.post(
      '${config.apiUrl}/upload',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.token}',
        },
      ),
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200 && response.data['status']) {
      var data = response.data['data'];
      return UploadResult(
        url: data['links']['url'],
        deleteURL: data['links']['delete'],
        thumbnailURL: data['links']['thumbnail_url'],
        filename: data['name'],
        size: data['size'],
        imageSize: ImageSize(data['width'], data['height']),
        createdAt: DateTime.parse(data['date']),
      );
    } else {
      throw ImageHostingError(
          'Upload failed: ${response.data['message'] ?? 'Unknown error'}');
    }
  }

  @override
  Future<bool> deleteImage(UploadResult item) async {
    var response = await dio.get(
      item.deleteURL,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.token}',
        },
      ),
    );

    return response.statusCode == 200 && response.data['status'];
  }

  @override
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0}) async {
    var response = await dio.get(
      '${config.apiUrl}/images',
      queryParameters: {
        'page': (offset ~/ limit) + 1,
        'per_page': limit,
        if (config.albumId != null) 'album_id': config.albumId,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${config.token}',
        },
      ),
    );

    if (response.statusCode == 200 && response.data['status']) {
      var data = response.data['data']['data'] as List;
      return data.map((item) => UploadResult(
        url: item['links']['url'],
        deleteURL: item['links']['delete'],
        thumbnailURL: item['links']['thumbnail_url'],
        filename: item['name'],
        size: item['size'],
        imageSize: ImageSize(item['width'], item['height']),
        createdAt: DateTime.parse(item['date']),
      )).toList();
    } else {
      throw ImageHostingError(
          'Failed to get uploaded images: ${response.data['message'] ?? 'Unknown error'}');
    }
  }
}