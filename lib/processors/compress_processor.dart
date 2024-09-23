import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../core/config_field.dart';
import 'package:image/image.dart' as img;
import '../generated/l10n.dart';
import 'image_processor.dart';
import 'package:path/path.dart' as path;

class CompressOptions implements ProcessingOptions {
  int quality;

  @override
  String get name => S.current.compress;

  CompressOptions({
    this.quality = 85,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'compress',
        'quality': quality,
      };

  factory CompressOptions.fromJson(Map<String, dynamic> json) {
    return CompressOptions(
      quality: json['quality'] ?? 85,
    );
  }

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
          key: 'quality',
          label: S.current.compressionQuality,
          value: quality,
          type: ConfigFieldType.number),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'quality':
        quality = int.parse(value);
        break;
    }
  }
}

class CompressProcessor implements ImageProcessor {
  @override
  Future<File> process(File image, ProcessingOptions options) async {
    if (options is! CompressOptions) {
      throw ArgumentError('Invalid options type');
    }

    final rawImage = img.decodeImage(await image.readAsBytes())!;

    var extension = image.path.split('.').last.toLowerCase();

    if (extension == 'gif') {
      return image;
    }
    Uint8List bytes;
    if (extension == 'png') {
      bytes = img.encodePng(rawImage, level: options.quality);
    } else {
      bytes = img.encodeJpg(rawImage, quality: options.quality);
      extension = 'jpg';
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
        '${tempDir.path}/${path.basenameWithoutExtension(path.basename(image.path))}.$extension');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }
}
