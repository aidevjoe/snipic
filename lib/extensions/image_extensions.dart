import 'dart:typed_data';

import 'package:image/image.dart' as img;

extension ImageEncodeExtension on img.Image {
  Uint8List? encodeImage(String format) {
    final fm = format.toLowerCase();
    final image = this;
    switch (fm) {
      case "jpg":
      case "jpeg":
        return img.encodeJpg(image);
      case "png":
        return img.encodePng(image);
      case "gif":
        return img.encodeGif(image);
      case "bmp":
        return img.encodeBmp(image);
      case "ico":
        return img.encodeIco(image);
      case "tiff":
        return img.encodeTiff(image);
      case "pvr":
        return img.encodePvr(image);
      case "tga":
        return img.encodeTga(image);
      case "cur":
        return img.encodeCur(image);
      case "heif":
      case "heic":
      case "webp":
        return null;
    }
    return null;
  }
}
