import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

import '../configs/aws_s3_config.dart';
import '../core/error.dart';
import '../core/image_hosting_engine.dart';
import '../core/upload_result.dart';

class AWSS3Engine extends ImageHostingEngine<AWSS3Config> {
  AWSS3Engine(super.config);

  @override
  Future<UploadResult> uploadImage(File image,
      {ProgressCallback? onProgress}) async {
    var filename = getTimestampedFilename(image.path);
    var date = _getAmzDate();
    var contentType = 'image/${filename.split('.').last}';

    var headers = _generateHeaders('PUT', '/$filename', contentType, date);

    var response = await dio.put(
      'https://${config.bucket}.s3.${config.region}.amazonaws.com/$filename',
      data: image.openRead(),
      options: Options(
        headers: headers,
      ),
      onSendProgress: onProgress,
    );

    if (response.statusCode == 200) {
      var imageUrl = config.customDomain != null
          ? '${config.customDomain}/$filename'
          : 'https://${config.bucket}.s3.${config.region}.amazonaws.com/$filename';
      return UploadResult(
        url: imageUrl,
        deleteURL: imageUrl,
        thumbnailURL:
            imageUrl, // AWS S3 doesn't provide built-in image resizing
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
    var date = _getAmzDate();

    var headers = _generateHeaders('DELETE', '/$filename', '', date);

    var response = await dio.delete(
      'https://${config.bucket}.s3.${config.region}.amazonaws.com/$filename',
      options: Options(
        headers: headers,
      ),
    );

    return response.statusCode == 204;
  }

  @override
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0}) async {
    var date = _getAmzDate();

    var headers = _generateHeaders('GET', '/', '', date);

    var response = await dio.get(
      'https://${config.bucket}.s3.${config.region}.amazonaws.com',
      queryParameters: {
        'max-keys': limit,
        'marker': offset.toString(),
      },
      options: Options(
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      var xmlResponse = response.data as String;
      var document = XmlDocument.parse(xmlResponse);
      var contents = document.findAllElements('Contents');

      return contents.map((content) {
        var key = content.findElements('Key').first.innerText;
        var size = int.parse(content.findElements('Size').first.innerText);
        var lastModified = DateTime.parse(
            content.findElements('LastModified').first.innerText);

        var url = config.customDomain != null
            ? '${config.customDomain}/$key'
            : 'https://${config.bucket}.s3.${config.region}.amazonaws.com/$key';

        return UploadResult(
          url: url,
          deleteURL: url,
          thumbnailURL: url, // AWS S3 doesn't provide built-in image resizing
          filename: key,
          size: size,
          createdAt: lastModified,
        );
      }).toList();
    } else {
      throw ImageHostingError(
          'Failed to get uploaded images with status: ${response.statusCode}');
    }
  }

  String _getAmzDate() {
    var now = DateTime.now().toUtc();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}T${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}Z';
  }

  Map<String, String> _generateHeaders(
      String method, String uri, String contentType, String date) {
    var headers = {
      'x-amz-date': date,
      'x-amz-content-sha256': 'UNSIGNED-PAYLOAD',
    };

    if (contentType.isNotEmpty) {
      headers['Content-Type'] = contentType;
    }

    var canonicalRequest = _createCanonicalRequest(method, uri, headers);
    var stringToSign = _createStringToSign(canonicalRequest, date);
    var signature = _calculateSignature(stringToSign, date);

    var authorization =
        'AWS4-HMAC-SHA256 Credential=${config.accessKeyId}/${date.substring(0, 8)}/${config.region}/s3/aws4_request, SignedHeaders=${_getSignedHeaders(headers)}, Signature=$signature';

    headers['Authorization'] = authorization;

    return headers;
  }

  String _createCanonicalRequest(
      String method, String uri, Map<String, String> headers) {
    var canonicalHeaders = headers.entries
        .map((e) => '${e.key.toLowerCase()}:${e.value}\n')
        .join();
    var signedHeaders = _getSignedHeaders(headers);

    return '$method\n$uri\n\n$canonicalHeaders\n$signedHeaders\nUNSIGNED-PAYLOAD';
  }

  String _getSignedHeaders(Map<String, String> headers) {
    final sign = headers.keys.map((key) => key.toLowerCase()).toList();
    sign.sort();
    return sign.join(';');
  }

  String _createStringToSign(String canonicalRequest, String date) {
    var hashedCanonicalRequest =
        sha256.convert(utf8.encode(canonicalRequest)).toString();
    return 'AWS4-HMAC-SHA256\n$date\n${date.substring(0, 8)}/${config.region}/s3/aws4_request\n$hashedCanonicalRequest';
  }

  String _calculateSignature(String stringToSign, String date) {
    var kDate = Hmac(sha256, utf8.encode('AWS4${config.secretAccessKey}'))
        .convert(utf8.encode(date.substring(0, 8)));
    var kRegion = Hmac(sha256, kDate.bytes).convert(utf8.encode(config.region));
    var kService = Hmac(sha256, kRegion.bytes).convert(utf8.encode('s3'));
    var kSigning =
        Hmac(sha256, kService.bytes).convert(utf8.encode('aws4_request'));
    return Hmac(sha256, kSigning.bytes)
        .convert(utf8.encode(stringToSign))
        .toString();
  }
}
