import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../configs/tencent_config.dart';
import '../core/error.dart';
import '../core/image_hosting_engine.dart';
import '../core/upload_result.dart';
import 'package:xml/xml.dart';

class TencentEngine extends ImageHostingEngine<TencentConfig> {
  TencentEngine(super.config);

  @override
  Future<UploadResult> uploadImage(File image,
      {ProgressCallback? onProgress}) async {
    var filename = getTimestampedFilename(image.path);
    var date = _getGMTDate();
    var contentType = 'image/${filename.split('.').last}';

    var authorization = _generateAuthorization('put', filename, date);

    var response = await dio.put(
      'https://${config.bucket}-${config.appId}.cos.${config.region}.myqcloud.com/$filename',
      data: image.openRead(),
      options: Options(
        headers: {
          'Authorization': authorization,
          'Date': date,
          'Content-Type': contentType,
        },
      ),
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200) {
      var imageUrl =
          'https://${config.bucket}-${config.appId}.cos.${config.region}.myqcloud.com/$filename';
      return UploadResult(
        url: imageUrl,
        deleteURL: imageUrl,
        thumbnailURL: '$imageUrl?imageMogr2/thumbnail/200x',
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
    var date = _getGMTDate();

    var authorization = _generateAuthorization('delete', filename, date);

    var response = await dio.delete(
      item.deleteURL,
      options: Options(
        headers: {
          'Authorization': authorization,
          'Date': date,
        },
      ),
    );

    return response.statusCode == 204;
  }

  @override
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0}) async {
    var date = _getGMTDate();
    var authorization = _generateAuthorization('get', '', date);

    var response = await dio.get(
      'https://${config.bucket}-${config.appId}.cos.${config.region}.myqcloud.com',
      queryParameters: {
        'max-keys': limit,
        'marker': offset.toString(),
      },
      options: Options(
        headers: {
          'Authorization': authorization,
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
        var size = int.parse(content.findElements('Size').first.innerText);
        var lastModified = content.findElements('LastModified').first.innerText;

        var imageUrl =
            'https://${config.bucket}-${config.appId}.cos.${config.region}.myqcloud.com/$key';

        results.add(UploadResult(
          url: imageUrl,
          deleteURL: imageUrl,
          thumbnailURL: '$imageUrl?imageMogr2/thumbnail/200x',
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

  String _getGMTDate() {
    return HttpDate.format(DateTime.now().toUtc());
  }

  String _generateAuthorization(
      String httpMethod, String resource, String date) {
    var signTime =
        '${DateTime.now().millisecondsSinceEpoch ~/ 1000};${DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600}';
    var httpString =
        '$httpMethod\n/$resource\n\nhost=${config.bucket}-${config.appId}.cos.${config.region}.myqcloud.com\n';
    var stringToSign =
        'sha1\n$signTime\n${sha1.convert(utf8.encode(httpString)).toString()}\n';

    var signKey = Hmac(sha1, utf8.encode(config.secretKey))
        .convert(utf8.encode(signTime))
        .toString();
    var signature = Hmac(sha1, utf8.encode(signKey))
        .convert(utf8.encode(stringToSign))
        .toString();

    return 'q-sign-algorithm=sha1&q-ak=${config.secretId}&q-sign-time=$signTime&q-key-time=$signTime&q-header-list=host&q-url-param-list=&q-signature=$signature';
  }
}
