
import 'dart:io';
import 'package:dio/dio.dart';

import '../core/image_hosting_engine.dart';
import '../configs/engine_config.dart';
import '../processors/image_processor.dart';
import '../core/upload_result.dart';

class ImageHostingManager {
  ImageHostingEngine engine;
  final Map<String, ImageProcessor> processors;
  final List<ProcessingOptions> processingOptions;

  ImageHostingManager({
    required EngineConfig initialConfig,
    required this.processors,
    required this.processingOptions,
  }) : engine = EngineConfig.createEngine(initialConfig);

  Future<UploadResult> uploadImage(File image, {ProgressCallback? onProgress}) async {
    File processedImage = await _processImage(image);
    return await engine.uploadImage(processedImage, onProgress: onProgress);
  }

  Future<File> _processImage(File image) async {
    File processedImage = image;
    for (var option in processingOptions) {
      final processor = processors[option.runtimeType.toString()];
      if (processor != null) {
        processedImage = await processor.process(processedImage, option);
      }
    }
    return processedImage;
  }

  void updateEngine(EngineConfig newConfig) {
    engine = EngineConfig.createEngine(newConfig);
  }


  Future<bool> deleteImage(UploadResult item) async {
    return await engine.deleteImage(item);
  }

  Future<List<UploadResult>> getUploadedImages({int limit = 20, int offset = 0}) async {
    return await engine.getUploadedImages(limit: limit, offset: offset);
  }
}