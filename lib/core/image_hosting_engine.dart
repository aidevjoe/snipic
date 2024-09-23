import 'dart:io';
import 'package:dio/dio.dart';
import '../configs/engine_config.dart';
import 'upload_result.dart';
import 'package:path/path.dart' as path;

abstract class ImageHostingEngine<T extends EngineConfig> {
  T config;
  final Dio dio = Dio(BaseOptions(validateStatus: (status) => status! < 500));

  ImageHostingEngine(this.config);

  Future<UploadResult> uploadImage(File image, {ProgressCallback? onProgress});
  Future<bool> deleteImage(UploadResult item);
  Future<List<UploadResult>> getUploadedImages(
      {int limit = 20, int offset = 0});

  void updateConfig(T newConfig) {
    config = newConfig;
  }

  String getTimestampedFilename(String originalPath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(originalPath);
    final basename = path.basenameWithoutExtension(originalPath);
    return '${basename}_$timestamp$extension';
  }
}
