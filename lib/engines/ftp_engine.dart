// import 'dart:io';
// import 'package:ftpconnect/ftpconnect.dart';
// import 'package:dartssh2/dartssh2.dart';

// import '../configs/ftp_config.dart';
// import '../core/image_hosting_engine.dart';
// import '../core/upload_result.dart';

// class FtpEngine extends ImageHostingEngine<FTPConfig> {
//   FtpEngine(super.config);

//   @override
//   Future<UploadResult> uploadImage(File image,
//       {ProgressCallback? onProgress}) async {
//     var filename = getTimestampedFilename(image.path);
//     var fullPath = '${config.basePath}/$filename';

//     if (config.useSFTP) {
//       var client = SSHClient(
//         host: config.host,
//         port: config.port,
//         username: config.username,
//         passwordOrKey: config.password,
//       );

//       try {
//         await client.connect();
//         await client.sftpUpload(
//           path: image.path,
//           toPath: fullPath,
//           callback: (progress) {
//             if (onProgress != null) {
//               onProgress(progress, 100);
//             }
//           },
//         );
//       } finally {
//         client.disconnect();
//       }
//     } else {
//       var ftpClient = FTPConnect(config.host,
//           port: config.port, user: config.username, pass: config.password);

//       try {
//         await ftpClient.connect();
//         await ftpClient.uploadFile(
//           image,
//           sRemoteName: fullPath,
//           pCallback: (progress) {
//             if (onProgress != null) {
//               onProgress(progress.bytesSent.toDouble(), progress.totalBytes.toDouble());
//             }
//           },
//         );
//       } finally {
//         await ftpClient.disconnect();
//       }
//     }

//     var imageUrl = config.customDomain != null
//         ? '${config.customDomain}$fullPath'
//         : 'ftp://${config.host}:${config.port}$fullPath';
//     return UploadResult(
//       url: imageUrl,
//       deleteURL: imageUrl,
//       thumbnailURL: imageUrl,  // FTP doesn't provide built-in image resizing
//       filename: filename,
//       size: image.lengthSync(),
//     );
//   }

//   @override
//   Future<bool> deleteImage(UploadResult item) async {
//     var fullPath = _getFullPathFromUrl(item.deleteUrl);

//     if (config.useSFTP) {
//       var client = SSHClient(
//         host: config.host,
//         port: config.port,
//         username: config.username,
//         passwordOrKey: config.password,
//       );

//       try {
//         await client.connect();
//         await client.execute('rm $fullPath');
//         return true;
//       } catch (e) {
//         return false;
//       } finally {
//         client.disconnect();
//       }
//     } else {
//       var ftpClient = FTPConnect(config.host,
//           port: config.port, user: config.username, pass: config.password);

//       try {
//         await ftpClient.connect();
//         await ftpClient.deleteFile(fullPath);
//         return true;
//       } catch (e) {
//         return false;
//       } finally {
//         await ftpClient.disconnect();
//       }
//     }
//   }

//   @override
//   Future<List<UploadResult>> getUploadedImages(
//       {int limit = 20, int offset = 0}) async {
//     if (config.useSFTP) {
//       var client = SSHClient(
//         host: config.host,
//         port: config.port,
//         username: config.username,
//         passwordOrKey: config.password,
//       );

//       try {
//         await client.connect();
//         var result = await client.execute('ls -l ${config.basePath}');
//         var lines = result.split('\n').skip(1).toList();  // Skip the first line which is total
//         return _parseListingToUploadResults(lines.skip(offset).take(limit).toList());
//       } finally {
//         client.disconnect();
//       }
//     } else {
//       var ftpClient = FTPConnect(config.host,
//           port: config.port, user: config.username, pass: config.password);

//       try {
//         await ftpClient.connect();
//         var listing = await ftpClient.listDirectoryContent(config.basePath);
//         return _parseListingToUploadResults(listing.skip(offset).take(limit).toList());
//       } finally {
//         await ftpClient.disconnect();
//       }
//     }
//   }

//   List<UploadResult> _parseListingToUploadResults(List<dynamic> listing) {
//     return listing.map((item) {
//       var name = item is FTPEntry ? item.name : item.split(' ').last;
//       var size = item is FTPEntry ? item.size : int.parse(item.split(' ')[4]);
//       var fullPath = '${config.basePath}/$name';
//       var url = config.customDomain != null
//           ? '${config.customDomain}$fullPath'
//           : 'ftp://${config.host}:${config.port}$fullPath';

//       return UploadResult(
//         url: url,
//         deleteURL: url,
//         thumbnailURL: url,  // FTP doesn't provide built-in image resizing
//         filename: name,
//         size: size,
//       );
//     }).toList();
//   }

//   String _getFullPathFromUrl(String url) {
//     if (config.customDomain != null && url.startsWith(config.customDomain!)) {
//       return url.substring(config.customDomain!.length);
//     } else if (url.startsWith('ftp://${config.host}:${config.port}')) {
//       return url.substring('ftp://${config.host}:${config.port}'.length);
//     } else {
//       throw ArgumentError('Invalid URL: $url');
//     }
//   }
// }