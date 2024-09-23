import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n.dart';
import '../configs/engine_config.dart';
import '../core/error.dart';
import '../core/upload_result.dart';
import '../manager/config_manager.dart';
import '../manager/image_hosting_manager.dart';

class ImageHostingUploadPage extends StatefulWidget {
  const ImageHostingUploadPage({super.key});

  @override
  State<ImageHostingUploadPage> createState() => _ImageHostingUploadPageState();
}

class _ImageHostingUploadPageState extends State<ImageHostingUploadPage>
    with AutomaticKeepAliveClientMixin {
  final List<ImageUploadItem> _imageItems = [];
  bool _isUploading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ConfigManager>(
      builder: (context, configManager, child) {
        return Scaffold(
          appBar: AppBar(
            title: _buildEngineDropdown(configManager),
            actions: [
              if (_imageItems.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: _clearAllImages,
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(15),
            child: _buildBody(configManager),
          ),
          bottomNavigationBar: _buildBottomBar(configManager),
        );
      },
    );
  }

  Widget _buildEngineDropdown(ConfigManager configManager) {
    return DropdownButton<EngineConfigWrapper>(
      value: configManager.currentConfig,
      icon: const SizedBox.shrink(),
      onChanged: (EngineConfigWrapper? value) {
        if (value != null) {
          configManager.setCurrentConfig(value);
          configManager.saveConfig();
          setState(() {});
        }
      },
      items: configManager.configurations.map((config) {
        return DropdownMenuItem<EngineConfigWrapper>(
          value: config,
          child: Text('${config.name} (${config.config.engineName})'),
        );
      }).toList(),
      padding: EdgeInsets.zero,
      alignment: Alignment.center,
      borderRadius: BorderRadius.circular(5),
      focusColor: Colors.transparent,
      underline: Container(),
      elevation: 2,
    );
  }

  Widget _buildBody(ConfigManager configManager) {
    return _imageItems.isEmpty
        ? _buildEmptyState()
        : Column(
            children: [
              if (!configManager.currentConfig.config.isShowConfigOptions)
                _buildSecurityWarning(),
              Expanded(child: _buildImageGrid()),
            ],
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: InkWell(
        onTap: _selectImages,
        child: Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: const Icon(Icons.add_rounded, size: 60, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: _imageItems.length + 1,
      itemBuilder: (context, index) {
        if (index == _imageItems.length) {
          return Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: AspectRatio(
                aspectRatio: 1.0,
                child: InkWell(
                  onTap: _selectImages,
                  child: const Icon(Icons.add_rounded,
                      size: 30, color: Colors.grey),
                )),
          );
        }
        final item = _imageItems[index];
        return _ImageUploadTile(
          key: ValueKey(item.file.path),
          item: item,
          onRemove: () => _removeImage(index),
          onRetry: item.status == UploadStatus.failed
              ? () => _retryUpload(index)
              : null,
        );
      },
    );
  }

  Widget _buildSecurityWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.yellow.shade100,
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              S.of(context).uploadedImagesMayBePublic,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ConfigManager configManager) {
    if (_imageItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (_imageItems.any((item) =>
                item.status == UploadStatus.completed &&
                item.result != null)) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: _copyAllUrls,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: Text(S.of(context).copy),
                ),
              ),
              const SizedBox(width: 12)
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: _isUploading ||
                        !_imageItems.any((item) =>
                            item.status == UploadStatus.notStarted ||
                            item.status == UploadStatus.failed)
                    ? null
                    : () => _uploadImages(configManager),
                style: ButtonStyle(
                  elevation: WidgetStateProperty.all(0),
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) =>
                          states.contains(WidgetState.disabled)
                              ? Theme.of(context).primaryColor.withOpacity(0.5)
                              : Theme.of(context).primaryColor),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
                child: Text(_isUploading
                    ? S.of(context).uploading
                    : S.of(context).upload),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImages() async {
    final pickedFiles = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (pickedFiles == null || pickedFiles.files.isNotEmpty) {
      setState(() {
        _imageItems.addAll(
          pickedFiles!.files
              .where((file) =>
                  !_imageItems.any((item) => item.file.path == file.path))
              .map((file) => ImageUploadItem(file: File(file.path!))),
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageItems.removeAt(index);
    });
  }

  void _clearAllImages() {
    setState(() {
      _imageItems.clear();
    });
  }

  Future<void> _uploadImages(ConfigManager configManager) async {
    if (_imageItems.isEmpty) return;

    if (!configManager.currentConfig.config.isValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).incompleteConfigurationMsg)));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final manager = Provider.of<ImageHostingManager>(context, listen: false);

    try {
      final itemsToUpload = _imageItems
          .where((item) =>
              item.status == UploadStatus.notStarted ||
              item.status == UploadStatus.failed)
          .toList();

      await Future.wait(
          itemsToUpload.map((item) => _uploadSingleImage(item, manager)));

      final uploadedCount = itemsToUpload
          .where((item) => item.status == UploadStatus.completed)
          .length;
      if (!mounted) return;
      if (uploadedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "$uploadedCount ${S.of(context).imagesUploadedSuccessfully}")));
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadSingleImage(
      ImageUploadItem item, ImageHostingManager manager) async {
    if (item.status != UploadStatus.notStarted &&
        item.status != UploadStatus.failed) return;

    setState(() {
      item.status = UploadStatus.uploading;
      item.progress = 0;
      item.errorMessage = null; // Reset error message
    });

    try {
      final result = await manager.uploadImage(
        item.file,
        onProgress: (sent, total) {
          setState(() {
            item.progress = sent / total;
          });
        },
      );
      setState(() {
        item.status = UploadStatus.completed;
        item.result = result;
      });
    } on DioException catch (e) {
      setState(() {
        item.status = UploadStatus.failed;
        item.errorMessage = e.message; // Store error message
      });
    } on ImageHostingError catch (e) {
      setState(() {
        item.status = UploadStatus.failed;
        item.errorMessage = e.message; // Store error message
      });
    } catch (e) {
      setState(() {
        item.status = UploadStatus.failed;
        item.errorMessage = e.toString(); // Store error message
      });
    }
  }

  void _retryUpload(int index) {
    final item = _imageItems[index];
    setState(() {
      item.status = UploadStatus.notStarted;
      item.progress = 0;
    });
    _uploadSingleImage(
        item, Provider.of<ImageHostingManager>(context, listen: false));
  }

  void _copyAllUrls() {
    final urls = _imageItems
        .where((item) =>
            item.status == UploadStatus.completed && item.result != null)
        .map((item) => item.result!.url)
        .join('\n');

    Clipboard.setData(ClipboardData(text: urls));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).copiedToClipboard)),
    );
  }
}

class _ImageUploadTile extends StatelessWidget {
  final ImageUploadItem item;
  final VoidCallback onRemove;
  final VoidCallback? onRetry;

  const _ImageUploadTile({
    super.key,
    required this.item,
    required this.onRemove,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'image_${item.file.path}',
              child: Image.file(
                item.file,
                fit: BoxFit.cover,
              ),
            ),
            _buildOverlay(context),
            Positioned(
              top: 6,
              right: 6,
              child: _buildIconButton(
                icon: Icons.close,
                onPressed: onRemove,
              ),
            ),
            if (item.result != null)
              Positioned(
                bottom: 6,
                right: 6,
                child: _buildIconButton(
                  icon: Icons.copy,
                  onPressed: () => _copyToClipboard(context, item.result!.url),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(5),
          color: Colors.black.withOpacity(0.2),
          child: IconButton(
              icon: Icon(icon, color: Colors.white, size: 20),
              onPressed: onPressed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                overlayColor: Colors.transparent,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    switch (item.status) {
      case UploadStatus.uploading:
        return _buildUploadingOverlay(context);
      case UploadStatus.completed:
        return _buildCompletedOverlay();
      case UploadStatus.failed:
        return _buildFailedOverlay(context);
      case UploadStatus.notStarted:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUploadingOverlay(BuildContext context) {
    return ClipRRect(
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: item.progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(item.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedOverlay() {
    return ClipRRect(
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: const Center(
          child: Icon(Icons.check_circle_outline_rounded,
              color: Colors.white, size: 40),
        ),
      ),
    );
  }

  Widget _buildFailedOverlay(BuildContext context) {
    return ClipRRect(
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: item.errorMessage ?? S.of(context).unknownError,
                verticalOffset: 15,
                margin: const EdgeInsets.all(15),
                showDuration: const Duration(hours: 24),
                triggerMode: TooltipTriggerMode.tap,
                decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(color: Colors.white),
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 5),
              Text(
                S.of(context).uploadFailed,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(S.of(context).retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).copiedToClipboard)));
    }
  }
}

class ImageUploadItem {
  final File file;
  UploadStatus status;
  double progress;
  UploadResult? result;
  String? errorMessage;

  ImageUploadItem({
    required this.file,
    this.status = UploadStatus.notStarted,
    this.progress = 0,
    this.result,
    this.errorMessage,
  });
}

enum UploadStatus {
  notStarted,
  uploading,
  completed,
  failed,
}
