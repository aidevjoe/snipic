class ImageSize {
  final int width;
  final int height;

  ImageSize(this.width, this.height);
}

class UploadResult {
  final String url;
  final String thumbnailURL;
  final String deleteURL;
  final String filename;
  final ImageSize? imageSize;
  final int size;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;

  UploadResult({
    required this.url,
    required this.thumbnailURL,
    required this.deleteURL,
    required this.filename,
    this.imageSize,
    required this.size,
    this.createdAt,
    this.metadata = const {},
  });
}
