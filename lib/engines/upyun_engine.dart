import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../configs/upyun_config.dart';
import '../core/error.dart';
import '../core/image_hosting_engine.dart';
import '../core/upload_result.dart';

class UpyunEngine extends ImageHostingEngine<UpyunConfig> {
  UpyunEngine(super.config);

  @override
  Future<UploadResult> uploadImage(File image,
      {ProgressCallback? onProgress}) async {
    var filename = getTimestampedFilename(image.path);
    var date = HttpDate.format(DateTime.now().toUtc());
    var uri = '/${config.bucketName}/$filename';

    var authorization = _generateAuthorization('PUT', uri, date);

    var response = await dio.put(
      'https://v0.api.upyun.com$uri',
      data: image.openRead(),
      options: Options(
        headers: {
          'Authorization': authorization,
          'Date': date,
          'Content-Length': image.lengthSync().toString(),
        },
      ),
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200) {
      var imageUrl = '${config.domain}/$filename';
      return UploadResult(
        url: imageUrl,
        deleteURL: imageUrl,
        thumbnailURL: '$imageUrl!/both/200x200',
        filename: filename,
        size: image.lengthSync(),
      );
    } else {
      throw ImageHostingError(
          'Upload failed with status: ${response.statusCode}');
    }
  }

  @override
  Future<bool> deleteImage(UploadResult item) async {
    var filename = item.deleteURL.split('/').last;
    var date = HttpDate.format(DateTime.now().toUtc());
    var uri = '/${config.bucketName}/$filename';

    var authorization = _generateAuthorization('DELETE', uri, date);

    var response = await dio.delete(
      'https://v0.api.upyun.com$uri',
      options: Options(
        headers: {
          'Authorization': authorization,
          'Date': date,
        },
      ),
    );

    return response.statusCode == 200;
  }

  @override
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0}) async {
    var date = HttpDate.format(DateTime.now().toUtc());
    var uri = '/${config.bucketName}/${config.bucketName}';

    var authorization = _generateAuthorization('GET', uri, date);

    var response = await dio.get(
      'https://v0.api.upyun.com$uri',
      queryParameters: {
        'x-list-limit': limit,
        'x-list-iter': "",
      },
      options: Options(
        headers: {
          'Authorization': authorization,
          'Date': date,
        },
      ),
    );

    if (response.statusCode == 200) {
      var jsonResponse = response.data as List;
      return jsonResponse
          .map((item) => UploadResult(
                url: '${config.domain}/${item['name']}',
                deleteURL: '${config.domain}/${item['name']}',
                thumbnailURL: '${config.domain}/${item['name']}!/both/200x200',
                filename: item['name'],
                size: item['size'],
                createdAt:
                    DateTime.fromMillisecondsSinceEpoch(item['time'] * 1000),
              ))
          .toList();
    } else {
      throw ImageHostingError(
          'Failed to get uploaded images with status: ${response.data['msg']}');
    }
  }

  String _generateAuthorization(String method, String uri, String date) {
    var passwordMd5 =
        md5.convert(utf8.encode(config.operatorPassword)).toString();
    var stringToSign = '$method&$uri&$date';
    var signature = base64.encode(Hmac(sha1, utf8.encode(passwordMd5))
        .convert(utf8.encode(stringToSign))
        .bytes);
    return 'UPYUN ${config.operatorName}:$signature';
  }
}
