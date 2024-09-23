
import '../core/config_field.dart';
import '../core/image_hosting_engine.dart';
import '../engines/aliyun_engine.dart';
import '../engines/aws_s3_engine.dart';
import '../engines/chevereto_engine.dart';
import '../engines/imgur_engine.dart';
import '../engines/qiniu_engine.dart';
import '../engines/smms_engine.dart';
import '../engines/tencent_engine.dart';
import '../engines/upyun_engine.dart';
import 'aliyun_config.dart';
import 'aws_s3_config.dart';
import 'chevereto_config.dart';
import 'imgur_config.dart';
import 'qiniu_config.dart';
import 'smms_config.dart';
import 'tencent_config.dart';
import 'upyun_config.dart';

abstract class EngineConfig {
  String get engineName;
  String get engineIcon;
  bool get isSupportDelete;
  bool get isSupportGetUploadedImages;
  bool get isShowConfigOptions;
  Map<String, dynamic> toJson();
  List<ConfigField> getConfigFields();
  bool isValid();
  void updateField(String key, dynamic value);

  factory EngineConfig.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'smms':
        return SmmsConfig.fromJson(json);
      case 'imgur':
        return ImgurConfig.fromJson(json);
      case 'qiniu':
        return QiniuConfig.fromJson(json);
      case 'chevereto':
        return CheveretoConfig.fromJson(json);
      case 'tencent':
        return TencentConfig.fromJson(json);
      case 'aliyun':
        return AliyunConfig.fromJson(json);
      case 'upyun':
        return UpyunConfig.fromJson(json);
      case 'aws_s3':
        return AWSS3Config.fromJson(json);
      default:
        throw ArgumentError('Unknown engine type');
    }
  }

  static ImageHostingEngine createEngine(EngineConfig config) {
    if (config is SmmsConfig) {
      return SmmsEngine(config);
    } else if (config is ImgurConfig) {
      return ImgurEngine(config);
    } else if (config is QiniuConfig) {
      return QiniuEngine(config);
    } else if (config is CheveretoConfig) {
      return CheveretoEngine(config);
    } else if (config is TencentConfig) {
      return TencentEngine(config);
    } else if (config is AliyunConfig) {
      return AliyunEngine(config);
    } else if (config is UpyunConfig) {
      return UpyunEngine(config);
    } else if (config is AWSS3Config) {
      return AWSS3Engine(config);
    } else {
      throw ArgumentError('Unknown engine configuration');
    }
  }
}

class EngineConfigWrapper {
  String name;
  EngineConfig config;

  EngineConfigWrapper({required this.name, required this.config});

  Map<String, dynamic> toJson() => {
        'name': name,
        'config': config.toJson(),
      };

  factory EngineConfigWrapper.fromJson(Map<String, dynamic> json) {
    return EngineConfigWrapper(
      name: json['name'],
      config: EngineConfig.fromJson(json['config']),
    );
  }
}
