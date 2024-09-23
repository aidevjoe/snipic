import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

import '../configs/webdav_config.dart';
import '../core/error.dart';
import '../core/image_hosting_engine.dart';
import '../core/upload_result.dart';

class WebDavEngine extends ImageHostingEngine<WebDavConfig> {
  WebDavEngine(super.config);

  @override
  Future<UploadResult> uploadImage(File image,
      {ProgressCallback? onProgress}) async {
    var filename = getTimestampedFilename(image.path);
    var fullPath = '${config.basePath}/$filename';

    var response = await dio.put(
      '${config.serverUrl}$fullPath',
      data: image.openRead(),
      options: Options(
        headers: {
          'Authorization': 'Basic ${_getBasicAuth()}',
          'Content-Type': 'image/${filename.split('.').last}',
        },
      ),
      onSendProgress: onProgress,
    );

    if (response.statusCode == 201 || response.statusCode == 204) {
      var imageUrl = config.customDomain != null
          ? '${config.customDomain}$fullPath'
          : '${config.serverUrl}$fullPath';
      return UploadResult(
        url: imageUrl,
        deleteURL: imageUrl,
        thumbnailURL: imageUrl,  // WebDAV doesn't provide built-in image resizing
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
    var fullPath = _getFullPathFromUrl(item.deleteURL);

    var response = await dio.delete(
      '${config.serverUrl}$fullPath',
      options: Options(
        headers: {
          'Authorization': 'Basic ${_getBasicAuth()}',
        },
      ),
    );

    return response.statusCode == 204;
  }

  @override
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0}) async {
    var response = await dio.request(
      '${config.serverUrl}${config.basePath}',
      options: Options(
        method: 'PROPFIND',
        headers: {
          'Authorization': 'Basic ${_getBasicAuth()}',
          'Depth': '1',
        },
        responseType: ResponseType.plain,
      ),
    );

    if (response.statusCode == 207) {
      var xmlResponse = response.data as String;
      var document = XmlDocument.parse(xmlResponse);
      var responses = document.findAllElements('d:response');

      var results = <UploadResult>[];
      for (var response in responses.skip(offset).take(limit)) {
        var href = response.findElements('d:href').first.innerText;
        var propstat = response.findElements('d:propstat').first;
        var prop = propstat.findElements('d:prop').first;

        var contentLength = int.parse(prop.findElements('d:getcontentlength').first.innerText);
        var lastModified = DateTime.parse(prop.findElements('d:getlastmodified').first.innerText);

        var filename = href.split('/').last;
        var url = config.customDomain != null
            ? '${config.customDomain}$href'
            : '${config.serverUrl}$href';

        results.add(UploadResult(
          url: url,
          deleteURL: url,
          thumbnailURL: url,  // WebDAV doesn't provide built-in image resizing
          filename: filename,
          size: contentLength,
          createdAt: lastModified,
        ));
      }

      return results;
    } else {
      throw ImageHostingError(
          'Failed to get uploaded images with status: ${response.statusCode}');
    }
  }

  String _getBasicAuth() {
    return base64Encode(utf8.encode('${config.username}:${config.password}'));
  }

  String _getFullPathFromUrl(String url) {
    if (config.customDomain != null && url.startsWith(config.customDomain!)) {
      return url.substring(config.customDomain!.length);
    } else if (url.startsWith(config.serverUrl)) {
      return url.substring(config.serverUrl.length);
    } else {
      throw ArgumentError('Invalid URL: $url');
    }
  }
}