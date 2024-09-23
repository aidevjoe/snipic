import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../generated/l10n.dart';
import '../configs/engine_config.dart';
import '../core/upload_result.dart';
import '../manager/config_manager.dart';
import '../manager/image_hosting_manager.dart';

class ImageHostingGalleryPage extends StatefulWidget {
  const ImageHostingGalleryPage({super.key});

  @override
  State<ImageHostingGalleryPage> createState() =>
      _ImageHostingGalleryPageState();
}

class _ImageHostingGalleryPageState extends State<ImageHostingGalleryPage>
    with AutomaticKeepAliveClientMixin {
  final List<UploadResult> _images = [];
  final Set<UploadResult> _selectedImages = {};
  bool _isSelectionMode = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _loadImages();
      _scrollController.addListener(_scrollListener);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreIfNeeded();
    }
  }

  Future<void> _loadImages({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      if (_isLoading) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        if (!loadMore) {
          _offset = 0;
          _images.clear();
        }
      });
    }

    try {
      final configManager = Provider.of<ConfigManager>(context, listen: false);
      if (!configManager.currentConfig.config.isValid()) {
        setState(() {
          _errorMessage = S.of(context).incompleteConfigurationMsg;
          _hasMore = false;
        });
        return;
      } else if (!configManager
          .currentConfig.config.isSupportGetUploadedImages) {
        setState(() {
          _errorMessage = S.of(context).galleryNotSupported;
          _hasMore = false;
        });
        return;
      }

      final manager = Provider.of<ImageHostingManager>(context, listen: false);
      final newImages =
          await manager.getUploadedImages(limit: _limit, offset: _offset);

      debugPrint(
          'Loaded ${newImages.length} images offset: $_offset, page: ${_offset ~/ _limit + 1}');
      setState(() {
        _images.addAll(newImages);
        _offset += newImages.length;
        _hasMore = newImages.length == _limit;
      });
      // Check if we need to load more after the initial load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMoreIfNeeded();
      });
    } on UnimplementedError {
      setState(() {
        _errorMessage = S.of(context).galleryNotSupported;
        _hasMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint(e.toString());
      setState(() {
        _errorMessage = '$e';
        _hasMore = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _loadMoreIfNeeded() {
    if (!_hasMore || _isLoadingMore) return;
    final extentAfter = _scrollController.position.extentAfter;
    if (extentAfter == 0) {
      _loadImages(loadMore: true);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _offset = 0;
      _images.clear();
      _hasMore = true;
    });
    await _loadImages();
  }

  Future<void> _deleteImage(UploadResult image) async {
    // HUD.showProgress();
    try {
      final manager = Provider.of<ImageHostingManager>(context, listen: false);
      final success = await manager.deleteImage(image);
      if (success) {
        setState(() {
          _images.remove(image);
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).operationFailedError)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to delete image: $e")));
    } finally {
      // HUD.dismiss();
    }
  }

  void _toggleImageSelection(UploadResult image) {
    setState(() {
      if (_selectedImages.contains(image)) {
        _selectedImages.remove(image);
      } else {
        _selectedImages.add(image);
      }
    });
  }

  Future<void> _deleteSelectedImages() async {
    // HUD.showProgress();
    try {
      final manager = Provider.of<ImageHostingManager>(context, listen: false);
      List<Future<bool>> deleteFutures = [];
      for (var image in _selectedImages) {
        deleteFutures.add(manager.deleteImage(image));
      }
      final results = await Future.wait(deleteFutures);
      int successCount = results.where((success) => success).length;

      setState(() {
        _images.removeWhere((image) => _selectedImages.contains(image));
        _selectedImages.clear();
        _isSelectionMode = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(S
              .of(context)
              .deletedImagesMessage(successCount, results.length))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      // HUD.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ConfigManager>(
      builder: (context, configManager, child) {
        return Scaffold(
          appBar: AppBar(
            title: _buildEngineDropdown(configManager),
            actions: [
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteSelectedImages,
                ),
              if (_images.isNotEmpty)
                IconButton(
                  icon: Icon(_isSelectionMode
                      ? Icons.close
                      : Icons.select_all_rounded),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = !_isSelectionMode;
                      if (!_isSelectionMode) {
                        _selectedImages.clear();
                      }
                    });
                  },
                ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading && _images.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(strokeCap: StrokeCap.round));
    } else if (_errorMessage != null && _images.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    } else if (_images.isEmpty) {
      return Center(child: Text(S.of(context).noImagesFoundUploadFirst));
    } else {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final image = _images[index];
                        return ImageCard(
                          image: image,
                          onDelete: () => _deleteImage(image),
                          onToggleSelection: () => _toggleImageSelection(image),
                          isSelected: _selectedImages.contains(image),
                          isSelectionMode: _isSelectionMode,
                        );
                      },
                      childCount: _images.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _hasMore && _isLoadingMore
                      ? _buildLoadingIndicator()
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEngineDropdown(ConfigManager configManager) {
    return DropdownButton<EngineConfigWrapper>(
      value: configManager.currentConfig,
      icon: const SizedBox.shrink(),
      onChanged: (EngineConfigWrapper? value) {
        if (value != null) {
          configManager.setCurrentConfig(value);
          final manager =
              Provider.of<ImageHostingManager>(context, listen: false);
          manager.updateEngine(value.config);
          _handleRefresh();
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
}

class ImageCard extends StatelessWidget {
  final UploadResult image;
  final VoidCallback onDelete;
  final VoidCallback onToggleSelection;
  final bool isSelected;
  final bool isSelectionMode;

  const ImageCard({
    super.key,
    required this.image,
    required this.onDelete,
    required this.onToggleSelection,
    required this.isSelected,
    required this.isSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          isSelectionMode ? onToggleSelection : () => _showImageDetail(context),
      child: Card(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(imageUrl: image.thumbnailURL, fit: BoxFit.cover),
            if (isSelected)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImageDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageDetailModal(image: image, onDelete: onDelete),
    );
  }
}

class ImageDetailModal extends StatelessWidget {
  final UploadResult image;
  final VoidCallback onDelete;

  const ImageDetailModal({
    super.key,
    required this.image,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            children: [
              CachedNetworkImage(imageUrl: image.url, fit: BoxFit.contain),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    _buildInfoRow(S.of(context).filename, image.filename),
                    _buildInfoRow(
                        S.of(context).fileSize, _formatBytes(image.size)),
                    if (image.imageSize != null)
                      _buildInfoRow(S.of(context).dimensions,
                          '${image.imageSize!.width} x ${image.imageSize!.height}'),
                    _buildInfoRow(S.of(context).uploadTime,
                        _formatDate(image.createdAt!)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                              icon: const Icon(Icons.copy),
                              label: Text(S.of(context).copyLink),
                              style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  elevation: 0),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: image.url));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            S.of(context).copiedToClipboard)));
                              }),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: Text(S.of(context).delete),
                            onPressed: () {
                              onDelete();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                                elevation: 0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const int k = 1024;
    const List<String> sizes = [
      'B',
      'KB',
      'MB',
      'GB',
      'TB',
      'PB',
      'EB',
      'ZB',
      'YB'
    ];
    int i = (log(bytes) / log(k)).floor();
    return '${(bytes / pow(k, i)).toStringAsFixed(decimals)} ${sizes[i]}';
  }
}
