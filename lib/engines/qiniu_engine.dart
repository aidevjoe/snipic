import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../configs/qiniu_config.dart';
import '../core/error.dart';
import '../core/image_hosting_engine.dart';
import '../core/upload_result.dart';

class QiniuEngine extends ImageHostingEngine<QiniuConfig> {
  QiniuEngine(super.config);

  bool _hasMore = true;

  @override
  Future<UploadResult> uploadImage(File image,
      {ProgressCallback? onProgress}) async {
    var filename = getTimestampedFilename(image.path);
    var uploadToken = _generateUploadToken(filename);

    var formData = FormData.fromMap({
      'token': uploadToken,
      'key': filename,
      'file': await MultipartFile.fromFile(image.path, filename: filename),
    });

    var response = await dio.post(
      config.region,
      data: formData,
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      var imageUrl = '${config.domain}/${jsonResponse['key']}';
      return UploadResult(
        url: imageUrl,
        deleteURL: imageUrl,
        thumbnailURL: '$imageUrl?imageView2/2/w/200',
        filename: jsonResponse['key'],
        size: 0,
      );
    } else {
      throw ImageHostingError(
          'Upload failed with status: ${response.statusCode}');
    }
  }

  @override
  Future<bool> deleteImage(UploadResult item) async {
    var key = item.deleteURL.split('/').last;
    var encodedEntryURI =
        base64Url.encode(utf8.encode('${config.bucket}:$key'));
    var signingStr = '/delete/$encodedEntryURI\n';
    var sign = _signString(signingStr);

    var response = await dio.post(
      'https://rs.qiniu.com/delete/$encodedEntryURI',
      options:
          Options(headers: {'Authorization': 'QBox ${config.accessKey}:$sign'}),
    );
    return response.statusCode == 200;
  }

  @override
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0}) async {
    if (offset == 0) {
      config.lastMarker = null;
      _hasMore = true;
    }
    if (!_hasMore) {
      return [];
    }
    var encodedMarker = config.lastMarker != null ? config.lastMarker! : '';
    var signingStr =
        '/list?bucket=${config.bucket}&limit=$limit&marker=$encodedMarker\n';
    var sign = _signString(signingStr);

    var response = await dio.get(
      'https://rsf.qbox.me/list?bucket=${config.bucket}&limit=$limit&marker=$encodedMarker',
      options:
          Options(headers: {'Authorization': 'QBox ${config.accessKey}:$sign'}),
    );

    if (response.statusCode == 200) {
      var jsonResponse = response.data;
      config.lastMarker = jsonResponse['marker'] as String?;
      _hasMore = config.lastMarker != null && config.lastMarker!.isNotEmpty;
      return (jsonResponse['items'] as List)
          .map((item) => UploadResult(
                url: '${config.domain}/${item['key']}',
                deleteURL: '${config.domain}/${item['key']}',
                thumbnailURL:
                    '${config.domain}/${item['key']}?imageView2/2/w/200',
                filename: item['key'],
                size: item['fsize'],
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                    item['putTime'] ~/ 1000000),
                metadata: {'key': item['key']},
              ))
          .toList();
    } else {
      throw ImageHostingError(
          'Failed to get uploaded images with status: ${response.statusCode}');
    }
  }

  String _generateUploadToken(String key) {
    var putPolicy = json.encode({
      'scope': '${config.bucket}:$key',
      'deadline': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    });
    var encodedPutPolicy = base64Url.encode(utf8.encode(putPolicy));
    var sign = _signString(encodedPutPolicy);
    return '${config.accessKey}:$sign:$encodedPutPolicy';
  }

  String _signString(String input) {
    var hmac = Hmac(sha1, utf8.encode(config.secretKey));
    var digest = hmac.convert(utf8.encode(input));
    return base64Url.encode(digest.bytes);
  }
}
