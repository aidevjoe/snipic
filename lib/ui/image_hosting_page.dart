import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../generated/l10n.dart';
import '../configs/engine_config.dart';
import '../configs/imgur_config.dart';
import '../manager/config_manager.dart';
import '../manager/image_hosting_manager.dart';
import '../processors/compress_processor.dart';
import '../processors/resize_processor.dart';
import '../processors/watermark_processor.dart';
import 'image_hosting_gallery_page.dart';
import 'image_hosting_setting_page.dart';
import 'image_hosting_upload_page.dart';

class ImageHostingPage extends StatelessWidget {
  const ImageHostingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfigManager(
        configurations: [
          EngineConfigWrapper(
            name: S.of(context).defaultText,
            config: ImgurConfig(
                clientId: 'ae16bbf2e15d1f4',
                isShowConfigOptions: false,
                isAnonymous: true),
          ),
        ],
      ),
      child: Builder(
        builder: (context) {
          return ProxyProvider<ConfigManager, ImageHostingManager>(
            update: (_, config, __) => ImageHostingManager(
              initialConfig: config.currentConfig.config,
              processors: {
                'ResizeOptions': ResizeProcessor(),
                'CompressOptions': CompressProcessor(),
                'WatermarkOptions': WatermarkProcessor(),
              },
              processingOptions: config.processingOptions,
            ),
            child: const ImageHostingContent(),
          );
        },
      ),
    );
  }
}

class ImageHostingContent extends StatefulWidget {
  const ImageHostingContent({super.key});

  @override
  State<ImageHostingContent> createState() => _ImageHostingContentState();
}

class _ImageHostingContentState extends State<ImageHostingContent> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final configManager = Provider.of<ConfigManager>(context, listen: false);
    await configManager.loadConfig();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const ImageHostingTab();
  }
}

class ImageHostingTab extends StatefulWidget {
  const ImageHostingTab({super.key});

  @override
  State<ImageHostingTab> createState() => _ImageHostingTabState();
}

class _ImageHostingTabState extends State<ImageHostingTab> {
  int _selectedIndex = 0;
  final List<Widget Function()> _pageBuilders = [
    () => const ImageHostingUploadPage(),
    () => const ImageHostingGalleryPage(),
    () => const ImageHostingSettingsPage(),
  ];
  final List<Widget?> _pages = List.filled(3, null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(
          _pageBuilders.length,
          (index) => _buildLazyLoadedPage(index),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.cloud_upload),
            label: S.of(context).upload,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.photo_library),
            label: S.of(context).gallery,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: S.of(context).settings,
          ),
        ],
      ),
    );
  }

  Widget _buildLazyLoadedPage(int index) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (_pages[index] == null && _selectedIndex == index) {
          _pages[index] = _pageBuilders[index]();
        }
        return _pages[index] ?? const SizedBox.shrink();
      },
    );
  }
}
