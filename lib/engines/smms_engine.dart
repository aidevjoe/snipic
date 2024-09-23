import 'dart:io';
import 'package:dio/dio.dart';
import '../core/error.dart';
import '../core/image_hosting_engine.dart';
import '../configs/smms_config.dart';
import '../core/upload_result.dart';

// https://doc.sm.ms/#api-Image-Temporary_History
class SmmsEngine extends ImageHostingEngine<SmmsConfig> {
  SmmsEngine(super.config);

  @override
  Future<UploadResult> uploadImage(File image,
      {ProgressCallback? onProgress}) async {
    var url = '${config.host}/api/v2/upload';
    var filename = getTimestampedFilename(image.path);

    var formData = FormData.fromMap({
      'smfile': await MultipartFile.fromFile(image.path, filename: filename),
    });

    var response = await dio.post(
      url,
      data: formData,
      options: Options(headers: {'Authorization': config.apiKey}),
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      if (jsonResponse['success']) {
        var data = jsonResponse['data'];
        return UploadResult(
          url: data['url'],
          deleteURL: data['delete'],
          thumbnailURL: data['url'],
          filename: data['filename'],
          imageSize: ImageSize(data['width'], data['height']),
          size: data['size'],
        );
      } else {
        throw ImageHostingError('Upload failed: ${jsonResponse['message']}');
      }
    } else {
      throw ImageHostingError('Upload failed: ${response.statusCode}');
    }
  }

  @override
  Future<bool> deleteImage(UploadResult item) async {
    var response = await dio.get(item.deleteURL);
    return response.statusCode == 200;
  }

  @override
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0}) async {
    var url = '${config.host}/api/v2/upload_history';
    var response = await dio.get(
      url,
      queryParameters: {'limit': limit, 'page': offset ~/ limit + 1},
      options: Options(headers: {'Authorization': config.apiKey}),
    );

    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      if (jsonResponse['success']) {
        final data = (jsonResponse['data'] as List)
            .map((item) => UploadResult(
                  url: item['url'],
                  deleteURL: item['delete'],
                  thumbnailURL: item['url'],
                  filename: item['filename'],
                  imageSize: ImageSize(item['width'], item['height']),
                  createdAt: DateTime.parse(item['created_at']),
                  size: item['size'],
                ))
            .toList();

        // 根据时间排序
        data.sort((a, b) {
          // 处理 null 值
          if (a.createdAt == null && b.createdAt == null) {
            return 0;
          } else if (a.createdAt == null) {
            return 1;
          } else if (b.createdAt == null) {
            return -1;
          }
          // 降序排列
          return b.createdAt!.compareTo(a.createdAt!);
        });
        return data;
      } else {
        throw ImageHostingError(
            'Failed to get uploaded images: ${jsonResponse['message']}');
      }
    } else {
      throw ImageHostingError(
          'Failed to get uploaded images with status: ${response.statusCode}');
    }
  }
}
