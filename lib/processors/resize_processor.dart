import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:snipic/extensions/image_extensions.dart';
import '../../../../generated/l10n.dart';
import '../core/config_field.dart';
import 'image_processor.dart';

import 'package:path/path.dart' as path;

class ResizeOptions implements ProcessingOptions {
  int width;
  int height;
  bool maintainAspectRatio;

  @override
  String get name => S.current.resize;

  ResizeOptions({
    required this.width,
    this.height = 0,
    this.maintainAspectRatio = true,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'resize',
        'width': width,
        'height': height,
        'maintainAspectRatio': maintainAspectRatio,
      };

  factory ResizeOptions.fromJson(Map<String, dynamic> json) {
    return ResizeOptions(
      width: json['width'],
      height: json['height'] ?? 0,
      maintainAspectRatio: json['maintainAspectRatio'] ?? true,
    );
  }

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
          key: 'width',
          label: S.current.width,
          value: width,
          type: ConfigFieldType.number),
      ConfigField(
          key: 'height',
          label: S.current.height,
          value: height,
          type: ConfigFieldType.number),
      ConfigField(
          key: 'maintainAspectRatio',
          label: S.current.keepAspectRatio,
          value: maintainAspectRatio,
          type: ConfigFieldType.boolean),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'width':
        width = int.parse(value);
      case 'height':
        height = int.parse(value);
      case 'maintainAspectRatio':
        maintainAspectRatio = value;
    }
  }
}

class ResizeProcessor implements ImageProcessor {
  @override
  Future<File> process(File image, ProcessingOptions options) async {
    if (options is! ResizeOptions) {
      throw ArgumentError('Invalid options type');
    }
    var extension = image.path.split('.').last.toLowerCase();

    if (extension == 'gif') {
      return image;
    }
    final rawImage = img.decodeImage(await image.readAsBytes());
    if (rawImage == null) {
      return image;
    }
    img.Image resizedImage;

    if (options.maintainAspectRatio) {
      // 保持宽高比，等比例缩放
      double aspectRatio = rawImage.width / rawImage.height;
      int newWidth = options.width;
      int newHeight = options.height;

      if (newWidth / newHeight > aspectRatio) {
        newWidth = (newHeight * aspectRatio).round();
      } else {
        newHeight = (newWidth / aspectRatio).round();
      }

      resizedImage =
          img.copyResize(rawImage, width: newWidth, height: newHeight);
    } else {
      // 不保持宽高比，直接缩放到指定尺寸
      resizedImage = img.copyResize(rawImage,
          width: options.width, height: options.height);
    }
    var bytes = resizedImage.encodeImage(extension);
    if (bytes == null) {
      extension = 'jpg';
      bytes = img.encodeJpg(resizedImage);
    }
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
        '${tempDir.path}/${path.basenameWithoutExtension(path.basename(image.path))}.$extension');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }
}
