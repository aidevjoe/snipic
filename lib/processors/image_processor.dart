import 'dart:io';

import '../core/config_field.dart';
import 'compress_processor.dart';
import 'resize_processor.dart';
import 'watermark_processor.dart';

abstract class ProcessingOptions {
  String get name;
  Map<String, dynamic> toJson();
  List<ConfigField> getConfigFields();
  void updateField(String key, dynamic value);

  factory ProcessingOptions.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'resize':
        return ResizeOptions.fromJson(json);
      case 'compress':
        return CompressOptions.fromJson(json);
      case 'watermark':
        return WatermarkOptions.fromJson(json);
      default:
        throw ArgumentError('Unknown processing option type');
    }
  }
}

abstract class ImageProcessor {
  Future<File> process(File image, ProcessingOptions options);
}
