import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../configs/aliyun_config.dart';
import '../configs/aws_s3_config.dart';
import '../configs/chevereto_config.dart';
import '../configs/engine_config.dart';
import '../configs/imgur_config.dart';
import '../configs/qiniu_config.dart';
import '../configs/smms_config.dart';
import '../configs/tencent_config.dart';
import '../configs/upyun_config.dart';
import '../processors/image_processor.dart';

class ConfigManager extends ChangeNotifier {
  List<EngineConfigWrapper> _configurations;
  EngineConfigWrapper _currentConfig;
  List<ProcessingOptions> _processingOptions;


  ConfigManager({
    EngineConfigWrapper? initialConfig,
    required List<EngineConfigWrapper> configurations,
  })  : _currentConfig = initialConfig ?? configurations.first,
        _configurations = configurations,
        _processingOptions = [];

  EngineConfigWrapper get currentConfig => _currentConfig;
  List<EngineConfigWrapper> get configurations => _configurations;
  List<ProcessingOptions> get processingOptions => _processingOptions;

  void setCurrentConfig(EngineConfigWrapper config) {
    if (_configurations.contains(config)) {
      _currentConfig = config;
      notifyListeners();
    }
  }

  bool addConfiguration(EngineConfigWrapper config) {
    if (!_configurations.any((c) =>
        c.name == config.name &&
        c.config.engineName == config.config.engineName)) {
      _configurations.add(config);
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeConfiguration(EngineConfigWrapper config) {
    _configurations.remove(config);
    if (_currentConfig == config && _configurations.isNotEmpty) {
      _currentConfig = _configurations.first;
    }
    notifyListeners();
  }

  void addProcessingOption(ProcessingOptions option) {
    _processingOptions.add(option);
    notifyListeners();
  }

  void removeProcessingOption(ProcessingOptions option) {
    _processingOptions.remove(option);
    notifyListeners();
  }

  void updateConfigField(
      EngineConfigWrapper config, String key, dynamic value) {
    config.config.updateField(key, value);
    notifyListeners();
  }

  void updateProcessingField(int index, String key, dynamic value) {
    if (index >= 0 && index < _processingOptions.length) {
      _processingOptions[index].updateField(key, value);
      notifyListeners();
    }
  }

  Future<void> saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentConfigName', _currentConfig.name);
    await prefs.setString('configurations',
        jsonEncode(_configurations.map((c) => c.toJson()).toList()));
    await prefs.setString('processingOptions',
        jsonEncode(_processingOptions.map((o) => o.toJson()).toList()));
  }

  Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // prefs.remove('currentConfigName');
      // prefs.remove('configurations');
      // prefs.remove('processingOptions');
      final configurationsJson = prefs.getString('configurations');
      final currentConfigName = prefs.getString('currentConfigName');
      final processingOptionsJson = prefs.getString('processingOptions');

      if (configurationsJson != null) {
        final List<dynamic> configList = jsonDecode(configurationsJson);
        _configurations = configList
            .map((json) => EngineConfigWrapper.fromJson(json))
            .toList();
      }

      if (currentConfigName != null && _configurations.isNotEmpty) {
        _currentConfig = _configurations.firstWhere(
          (config) => config.name == currentConfigName,
          orElse: () => _configurations.first,
        );
      } else if (_configurations.isNotEmpty) {
        _currentConfig = _configurations.first;
      }

      if (processingOptionsJson != null) {
        final List<dynamic> optionsList = jsonDecode(processingOptionsJson);
        _processingOptions = optionsList
            .map((json) => ProcessingOptions.fromJson(json))
            .toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading config: $e');
      _currentConfig = EngineConfigWrapper(
        name: 'Default',
        config: createDefaultConfig('SM.MS'),
      );
      _configurations = [];
      _processingOptions = [];
    }
  }

  EngineConfig createDefaultConfig(String engineType) {
    switch (engineType) {
      case 'SM.MS':
        return SmmsConfig(apiKey: '');
      case 'Imgur':
        return ImgurConfig(clientId: '', clientSecret: '', refreshToken: '');
      case 'Qiniu':
        return QiniuConfig(
            accessKey: '', secretKey: '', bucket: '', domain: '');
      case 'Chevereto':
        return CheveretoConfig(apiUrl: '', apiKey: '');
      case 'Tencent':
        return TencentConfig(
            secretId: '', secretKey: '', bucket: '', region: '', appId: '');
      case 'Aliyun':
        return AliyunConfig(
            accessKeyId: '', accessKeySecret: '', bucket: '', region: '');
      case 'Upyun':
        return UpyunConfig(
            bucketName: '', operatorName: '', operatorPassword: '', domain: '');
      case "AWS S3":
        return AWSS3Config(
            accessKeyId: '',
            secretAccessKey: '',
            bucket: '',
            region: '',
            customDomain: '');
      default:
        throw ArgumentError('Unknown engine type: $engineType');
    }
  }

  bool createNewConfiguration(String name, String engineType) {
    final newConfig = createDefaultConfig(engineType);
    return addConfiguration(EngineConfigWrapper(name: name, config: newConfig));
  }

  bool isConfigNameUnique(String name) {
    return !_configurations.any((config) => config.name == name);
  }

  List<String> getAvailableEngineTypes() {
    return [
      'SM.MS',
      'Imgur',
      'Chevereto',
      'Qiniu',
      'Tencent',
      'Aliyun',
      'Upyun',
      // "AWS S3",
    ];
  }
}
