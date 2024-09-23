import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../generated/l10n.dart';
import '../core/config_field.dart';
import 'image_processor.dart';
import 'package:path/path.dart' as path;
import 'dart:ui' as ui;

enum PositionType {
  topLeft,
  topRight,
  center,
  bottomLeft,
  bottomRight;

  String get title {
    switch (this) {
      case PositionType.topLeft:
        return S.current.topLeft;
      case PositionType.topRight:
        return S.current.topRight;
      case PositionType.bottomLeft:
        return S.current.bottomLeft;
      case PositionType.center:
        return S.current.center;
      case PositionType.bottomRight:
        return S.current.bottomRight;
    }
  }
}

class WatermarkOptions implements ProcessingOptions {
  String text;
  int fontSize;
  int opacity;
  PositionType position;

  @override
  String get name => S.current.watermark;

  WatermarkOptions({
    this.text = "",
    this.fontSize = 48,
    this.opacity = 80,
    this.position = PositionType.bottomRight,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'watermark',
        'text': text,
        'fontSize': fontSize,
        'opacity': opacity,
        'position': position.name,
      };

  factory WatermarkOptions.fromJson(Map<String, dynamic> json) {
    return WatermarkOptions(
      text: json['text'] ?? S.current.watermarkText,
      fontSize: json['fontSize'] ?? 48,
      opacity: json['opacity'] ?? 80,
      position: PositionType.values.byName(json['position'] ?? 'bottomRight'),
    );
  }

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
        key: 'text',
        label: S.current.watermarkText,
        value: text,
        type: ConfigFieldType.text,
      ),
      ConfigField(
        key: 'fontSize',
        label: '${S.current.fontSize}(px)',
        value: fontSize,
        type: ConfigFieldType.number,
        min: 1,
        max: 100,
      ),
      ConfigField(
        key: 'opacity',
        label: '${S.current.opacity}(%)',
        value: opacity,
        type: ConfigFieldType.number,
        min: 1,
        max: 100,
      ),
      ConfigField(
        key: 'position',
        label: S.current.position,
        value: position.name,
        type: ConfigFieldType.select,
        options: PositionType.values
            .map((e) => ConfigFieldOption(label: e.title, value: e.name))
            .toList(),
      ),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'text':
        text = value;
        break;
      case 'fontSize':
        fontSize = int.tryParse(value) ?? 48;
        break;
      case 'opacity':
        opacity = int.tryParse(value) ?? 80;
        break;
      case 'position':
        position = PositionType.values.byName(value);
        break;
    }
  }
}

class WatermarkProcessor implements ImageProcessor {
  @override
  Future<File> process(File image, ProcessingOptions options) async {
    if (options is! WatermarkOptions) {
      throw ArgumentError('Invalid options type');
    }
    var extension = image.path.split('.').last.toLowerCase();
    if (extension == 'gif') {
      return image;
    }
    final imageBytes = await _addWatermark(image.readAsBytesSync(), options);

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
        '${tempDir.path}/${path.basenameWithoutExtension(image.path)}.png');
    await tempFile.writeAsBytes(imageBytes);
    return tempFile;
  }

  Future<Uint8List> _addWatermark(
      Uint8List imageBytes, WatermarkOptions options) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the original image
    ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final imgUi = await codec.getNextFrame();
    canvas.drawImage(imgUi.image, Offset.zero, Paint());

    // Prepare the text painter
    final textPainter = TextPainter(
      text: TextSpan(
        text: options.text,
        style: TextStyle(
          color: Color.fromRGBO(255, 255, 255, options.opacity / 100),
          fontSize: options.fontSize.toDouble(),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Calculate position
    final position = _calculatePosition(
      imgUi.image.width.toDouble(),
      imgUi.image.height.toDouble(),
      textPainter.width,
      textPainter.height,
      options.position,
      options.fontSize.toDouble(),
    );

    // Draw the text
    textPainter.paint(canvas, position);

    // Convert canvas to image
    final picture = recorder.endRecording();
    final pimg = await picture.toImage(imgUi.image.width, imgUi.image.height);
    final byteData = await pimg.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Offset _calculatePosition(
      double imageWidth,
      double imageHeight,
      double textWidth,
      double textHeight,
      PositionType position,
      double fontSize) {
    final padding = fontSize * 0.5;

    switch (position) {
      case PositionType.topLeft:
        return Offset(padding, padding);
      case PositionType.topRight:
        return Offset(imageWidth - textWidth - padding, padding);
      case PositionType.bottomLeft:
        return Offset(padding, imageHeight - textHeight - padding);
      case PositionType.bottomRight:
        return Offset(imageWidth - textWidth - padding,
            imageHeight - textHeight - padding);
      case PositionType.center:
      default:
        return Offset(
            (imageWidth - textWidth) / 2, (imageHeight - textHeight) / 2);
    }
  }
}
