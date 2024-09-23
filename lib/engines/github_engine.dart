import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

import '../configs/github_config.dart';
import '../core/error.dart';
import '../core/image_hosting_engine.dart';
import '../core/upload_result.dart';

class GitHubEngine extends ImageHostingEngine<GitHubConfig> {
  GitHubEngine(super.config);

  @override
  Future<UploadResult> uploadImage(File image,
      {ProgressCallback? onProgress}) async {
    var filename = getTimestampedFilename(image.path);
    var fullPath = '${config.path}/$filename';

    var content = base64Encode(await image.readAsBytes());

    var response = await dio.put(
      'https://api.github.com/repos/${config.owner}/${config.repo}/contents/$fullPath',
      data: {
        'message': 'Upload image $filename',
        'content': content,
        'branch': config.branch,
      },
      options: Options(
        headers: {
          'Authorization': 'token ${config.token}',
          'Accept': 'application/vnd.github.v3+json',
        },
      ),
      onSendProgress: onProgress,
    );

    if (response.statusCode == 201) {
      var data = response.data['content'];
      var imageUrl = data['download_url'];
      return UploadResult(
        url: imageUrl,
        deleteURL: imageUrl,
        thumbnailURL: imageUrl,  // GitHub doesn't provide thumbnails
        filename: filename,
        size: image.lengthSync(),
        createdAt: DateTime.now(),
      );
    } else {
      throw ImageHostingError(
          'Upload failed: ${response.data['message'] ?? 'Unknown error'}');
    }
  }

  @override
  Future<bool> deleteImage(UploadResult item) async {
    var filename = item.deleteURL.split('/').last;
    var fullPath = '${config.path}/$filename';

    // First, we need to get the file's SHA
    var getResponse = await dio.get(
      'https://api.github.com/repos/${config.owner}/${config.repo}/contents/$fullPath',
      options: Options(
        headers: {
          'Authorization': 'token ${config.token}',
          'Accept': 'application/vnd.github.v3+json',
        },
      ),
    );

    if (getResponse.statusCode != 200) {
      return false;
    }

    var sha = getResponse.data['sha'];

    // Now we can delete the file
    var deleteResponse = await dio.delete(
      'https://api.github.com/repos/${config.owner}/${config.repo}/contents/$fullPath',
      data: {
        'message': 'Delete image $filename',
        'sha': sha,
        'branch': config.branch,
      },
      options: Options(
        headers: {
          'Authorization': 'token ${config.token}',
          'Accept': 'application/vnd.github.v3+json',
        },
      ),
    );

    return deleteResponse.statusCode == 200;
  }

  @override
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0}) async {
    var response = await dio.get(
      'https://api.github.com/repos/${config.owner}/${config.repo}/contents/${config.path}',
      queryParameters: {
        'ref': config.branch,
      },
      options: Options(
        headers: {
          'Authorization': 'token ${config.token}',
          'Accept': 'application/vnd.github.v3+json',
        },
      ),
    );

    if (response.statusCode == 200) {
      var files = (response.data as List)
          .where((file) => file['type'] == 'file')
          .skip(offset)
          .take(limit)
          .toList();

      return files.map((file) => UploadResult(
        url: file['download_url'],
        deleteURL: file['download_url'],
        thumbnailURL: file['download_url'],  // GitHub doesn't provide thumbnails
        filename: file['name'],
        size: file['size'],
        createdAt: DateTime.now(),  // GitHub API doesn't provide creation time in this endpoint
      )).toList();
    } else {
      throw ImageHostingError(
          'Failed to get uploaded images: ${response.data['message'] ?? 'Unknown error'}');
    }
  }
}