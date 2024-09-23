import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

import '../configs/aliyun_config.dart';
import '../core/error.dart';
import '../core/image_hosting_engine.dart';
import '../core/upload_result.dart';

// https://help.aliyun.com/zh/oss/developer-reference/listobjects?spm=a2c4g.11186623.0.0.4bc67be449dfAf
class AliyunEngine extends ImageHostingEngine<AliyunConfig> {
  AliyunEngine(super.config);

  @override
  Future<UploadResult> uploadImage(File image,
      {ProgressCallback? onProgress}) async {
    var filename = getTimestampedFilename(image.path);
    var date = HttpDate.format(DateTime.now());
    var contentType = 'image/${filename.split('.').last}';

    var signature = _generateSignature('PUT', filename, date, contentType);

    var response = await dio.put(
      'https://${config.bucket}.oss-${config.region}.aliyuncs.com/$filename',
      data: image.openRead(),
      options: Options(
        headers: {
          'Authorization': 'OSS ${config.accessKeyId}:$signature',
          'Date': date,
          'Content-Type': contentType,
        },
      ),
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200) {
      var imageUrl =
          'https://${config.bucket}.oss-${config.region}.aliyuncs.com/$filename';
      return UploadResult(
        url: imageUrl,
        deleteURL: imageUrl,
        thumbnailURL: '$imageUrl?x-oss-process=image/resize,w_200',
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
    var filename = item.filename;
    var date = HttpDate.format(DateTime.now());

    var signature = _generateSignature('DELETE', filename, date, '');

    var response = await dio.delete(
      item.deleteURL,
      options: Options(
        headers: {
          'Authorization': 'OSS ${config.accessKeyId}:$signature',
          'Date': date,
        },
      ),
    );

    return response.statusCode == 204;
  }

  @override
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0}) async {
    var date = HttpDate.format(DateTime.now());
    var signature = _generateSignature('GET', '', date, '');
    if (offset == 0) {
      config.lastMarker = null;
    }
    var response = await dio.get(
      'https://${config.bucket}.oss-${config.region}.aliyuncs.com',
      queryParameters: {
        'max-keys': limit,
        'marker': config.lastMarker ?? '',
        'X-OSS-Process': 'meta=_last_modified_time'
      },
      options: Options(
        headers: {
          'Authorization': 'OSS ${config.accessKeyId}:$signature',
          'Date': date,
        },
      ),
    );

    if (response.statusCode == 200) {
      var xmlResponse = response.data as String;
      var xmlDocument = XmlDocument.parse(xmlResponse);

      var contents = xmlDocument.findAllElements('Contents');
      var results = <UploadResult>[];

      for (var content in contents) {
        var key = content.findElements('Key').first.innerText;
        config.lastMarker = key;
        var size = int.parse(content.findElements('Size').first.innerText);
        var lastModified = content.findElements('LastModified').first.innerText;

        var imageUrl =
            'https://${config.bucket}.oss-${config.region}.aliyuncs.com/$key';

        results.add(UploadResult(
          url: imageUrl,
          deleteURL: imageUrl,
          thumbnailURL: '$imageUrl?x-oss-process=image/resize,w_200',
          filename: key,
          size: size,
          createdAt: DateTime.parse(lastModified),
        ));
      }

      return results;
    } else {
      throw ImageHostingError(
          'Failed to get uploaded images with status: ${response.statusCode}');
    }
  }

  String _generateSignature(
      String httpMethod, String resource, String date, String contentType) {
    var stringToSign =
        '$httpMethod\n\n$contentType\n$date\n/${config.bucket}/$resource';
    var hmac = Hmac(sha1, utf8.encode(config.accessKeySecret));
    var digest = hmac.convert(utf8.encode(stringToSign));
    return base64.encode(digest.bytes);
  }
}
