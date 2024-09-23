class ImageHostingError implements Exception {
  final String message;

  ImageHostingError(this.message);

  @override
  String toString() {
    return 'ImageHostingError: $message';
  }
}
