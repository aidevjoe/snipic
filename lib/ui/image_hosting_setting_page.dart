import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../generated/l10n.dart';
import '../configs/engine_config.dart';
import '../core/config_field.dart';
import '../manager/config_manager.dart';
import '../processors/compress_processor.dart';
import '../processors/image_processor.dart';
import '../processors/resize_processor.dart';
import '../processors/watermark_processor.dart';

class ImageHostingSettingsPage extends StatefulWidget {
  const ImageHostingSettingsPage({super.key});

  @override
  State<ImageHostingSettingsPage> createState() =>
      _ImageHostingSettingsPageState();
}

class _ImageHostingSettingsPageState extends State<ImageHostingSettingsPage>
    with AutomaticKeepAliveClientMixin {
  late ConfigManager _configManager;
  late Map<String, TextEditingController> _controllers;

  @override
  bool get wantKeepAlive => true;

  late EngineConfigWrapper _currentConfig;

  @override
  void initState() {
    super.initState();
    _configManager = Provider.of<ConfigManager>(context, listen: false);
    _currentConfig = _configManager.currentConfig;
    _initControllers();
  }

  void _initControllers() {
    _controllers = {};
    final fields = _currentConfig.config.getConfigFields();
    for (var field in fields) {
      if (field.type == ConfigFieldType.text ||
          field.type == ConfigFieldType.number) {
        _controllers[field.key] =
            TextEditingController(text: field.value.toString());
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settings)),
      body: Consumer<ConfigManager>(
        builder: (context, configManager, child) {
          return ListView(
            padding: const EdgeInsets.all(15),
            children: [
              _buildConfigSelector(context, configManager),
              const SizedBox(height: 12),
              if (_currentConfig.config.isShowConfigOptions) ...[
                _buildCurrentConfigFields(context, configManager),
                const SizedBox(height: 12)
              ],
              _buildImageProcessingOptions(context, configManager),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _saveConfiguration(context, configManager),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(S.of(context).save),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfigSelector(
      BuildContext context, ConfigManager configManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.of(context).selectConfiguration,
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                    onPressed: () =>
                        _showAddConfigDialog(context, configManager),
                    icon: const Icon(Icons.add_rounded),
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )),
              ],
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<EngineConfigWrapper>(
              value: _currentConfig,
              items: configManager.configurations.map((config) {
                return DropdownMenuItem<EngineConfigWrapper>(
                  value: config,
                  child: Text('${config.name} (${config.config.engineName})'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _currentConfig = value;
                  _initControllers();
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageProcessingOptions(
      BuildContext context, ConfigManager configManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(left: 15, top: 15, right: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.of(context).imageProcessingOptions,
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                    onPressed: () =>
                        _showAddProcessingOptionDialog(context, configManager),
                    icon: const Icon(Icons.add_rounded),
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )),
              ],
            ),
            const SizedBox(height: 15),
            ...configManager.processingOptions.asMap().entries.map(
                  (entry) => _buildProcessingOptionFields(
                      context, entry.key, entry.value, configManager),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOptionFields(BuildContext context, int index,
      ProcessingOptions option, ConfigManager configManager) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(option.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                      onPressed: () =>
                          configManager.removeProcessingOption(option),
                      icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )),
                ],
              ),
              const SizedBox(height: 15),
              ...option.getConfigFields().map(
                    (field) => _buildConfigField(
                        context,
                        field,
                        (key, value) => configManager.updateProcessingField(
                            index, key, value)),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProcessingOptionDialog(
      BuildContext context, ConfigManager configManager) {
    FocusManager.instance.primaryFocus?.unfocus();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).addProcessingOption),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ...[
                  S.of(context).resize,
                  S.of(context).compress,
                  S.of(context).watermark
                ].map((type) {
                  return ListTile(
                    title: Text(type),
                    onTap: () {
                      if (type == S.of(context).resize) {
                        configManager.addProcessingOption(
                            ResizeOptions(width: 800, height: 600));
                      } else if (type == S.of(context).compress) {
                        configManager.addProcessingOption(CompressOptions());
                      } else if (type == S.of(context).watermark) {
                        configManager.addProcessingOption(WatermarkOptions());
                      }
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentConfigFields(
      BuildContext context, ConfigManager configManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${_currentConfig.config.engineName} ${S.of(context).configuration}',
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                    onPressed: () {
                      configManager.removeConfiguration(_currentConfig);
                      setState(() {
                        _currentConfig = configManager.currentConfig;
                        _initControllers();
                      });
                    },
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )),
              ],
            ),
            ..._currentConfig.config.getConfigFields().map((field) =>
                _buildConfigField(
                    context,
                    field,
                    (key, value) => configManager.updateConfigField(
                        _currentConfig, key, value))),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigField(BuildContext context, ConfigField field,
      Function(String, dynamic) updateField) {
    switch (field.type) {
      case ConfigFieldType.text:
      case ConfigFieldType.number:
        final controller = _controllers[field.key] ??
            TextEditingController(text: field.value.toString());
        _controllers[field.key] = controller;
        return Padding(
          padding: const EdgeInsets.only(top: 15),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: field.label),
            keyboardType: field.type == ConfigFieldType.number
                ? TextInputType.number
                : TextInputType.text,
            inputFormatters: field.type == ConfigFieldType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : [],
            onChanged: (value) => updateField(field.key, value),
          ),
        );
      case ConfigFieldType.slider:
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${field.label} (${field.value.toStringAsFixed(0)})"),
              Slider(
                  value: field.value.toDouble(),
                  min: field.min?.toDouble() ?? 0.0,
                  max: field.max?.toDouble() ?? 1.0,
                  onChanged: (value) => updateField(field.key, value)),
            ],
          ),
        );
      case ConfigFieldType.boolean:
        return SwitchListTile(
          title: Text(field.label),
          value: field.value,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onChanged: (value) => updateField(field.key, value),
        );
      case ConfigFieldType.select:
        return Padding(
          padding: const EdgeInsets.only(top: 15),
          child: DropdownButtonFormField<String>(
            value: field.value,
            decoration: InputDecoration(labelText: field.label),
            items: field.options!.map((option) {
              return DropdownMenuItem<String>(
                value: option.value,
                child: Text(option.label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                updateField(field.key, value);
              }
            },
          ),
        );
    }
  }

  void _showAddConfigDialog(BuildContext context, ConfigManager configManager) {
    String newConfigName = '';
    String? selectedEngineType;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).addNewConfiguration),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText: S.of(context).configurationName),
                    onChanged: (value) => setState(() {
                      newConfigName = value;
                    }),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    items: configManager.getAvailableEngineTypes().map((type) {
                      return DropdownMenuItem<String>(
                          value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) => setState(() {
                      selectedEngineType = value;
                    }),
                    decoration:
                        InputDecoration(labelText: S.of(context).engineType),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () {
                if (newConfigName.isEmpty || selectedEngineType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(S.of(context).configNameAndEngineRequired)),
                  );
                  return;
                }
                final result = configManager.createNewConfiguration(
                    newConfigName, selectedEngineType!);
                if (!result) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).configurationAlreadyExists),
                    ),
                  );
                  return;
                }
                _currentConfig = configManager.configurations.last;
                Navigator.of(context).pop();
                _initControllers();
                setState(() {});
              },
              child: Text(S.of(context).add),
            )
          ],
        );
      },
    );
  }

  void _saveConfiguration(
      BuildContext context, ConfigManager configManager) async {
    await configManager.saveConfig();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).configurationSaved)));
  }
}
