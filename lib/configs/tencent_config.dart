import '../core/config_field.dart';
import 'engine_config.dart';

// https://cloud.tencent.com/document/product/436/6224
class TencentConfig implements EngineConfig {
  String secretId;
  String secretKey;
  String bucket;
  String region;
  String appId;
  @override
  bool isShowConfigOptions;

  TencentConfig({
    required this.secretId,
    required this.secretKey,
    required this.bucket,
    required this.region,
    required this.appId,
    this.isShowConfigOptions = true,
  });

  @override
  String get engineName => 'Tencent COS';

  @override
  String get engineIcon => 'assets/tencent_icon.png';

  @override
  bool get isSupportDelete => true;

  @override
  bool get isSupportGetUploadedImages => true;

  @override
  bool isValid() =>
      secretId.isNotEmpty &&
      secretKey.isNotEmpty &&
      bucket.isNotEmpty &&
      region.isNotEmpty &&
      appId.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tencent',
        'secretId': secretId,
        'secretKey': secretKey,
        'bucket': bucket,
        'region': region,
        'appId': appId,
      };

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
          key: 'secretId',
          label: 'Secret ID',
          value: secretId,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'secretKey',
          label: 'Secret Key',
          value: secretKey,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'bucket',
          label: 'Bucket',
          value: bucket,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'region',
          label: 'Region',
          value: region,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'appId',
          label: 'App ID',
          value: appId,
          type: ConfigFieldType.text),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'secretId':
        secretId = value;
      case 'secretKey':
        secretKey = value;
      case 'bucket':
        bucket = value;
      case 'region':
        region = value;
      case 'appId':
        appId = value;
    }
  }

  static EngineConfig fromJson(Map<String, dynamic> json) {
    return TencentConfig(
      secretId: json['secretId'] ?? '',
      secretKey: json['secretKey'] ?? '',
      bucket: json['bucket'] ?? '',
      region: json['region'] ?? '',
      appId: json['appId'] ?? '',
    );
  }
}