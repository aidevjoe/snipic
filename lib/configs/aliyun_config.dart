import '../core/config_field.dart';
import 'engine_config.dart';

class AliyunConfig implements EngineConfig {
  String accessKeyId;
  String accessKeySecret;
  String bucket;
  String region;
  @override
  bool isShowConfigOptions;
  String? lastMarker;

  AliyunConfig({
    required this.accessKeyId,
    required this.accessKeySecret,
    required this.bucket,
    required this.region,
    this.isShowConfigOptions = true,
  });

  @override
  String get engineName => 'Aliyun OSS';

  @override
  String get engineIcon => 'assets/aliyun_icon.png';

  @override
  bool get isSupportDelete => true;

  @override
  bool get isSupportGetUploadedImages => true;

  @override
  bool isValid() =>
      accessKeyId.isNotEmpty &&
      accessKeySecret.isNotEmpty &&
      bucket.isNotEmpty &&
      region.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'aliyun',
        'accessKeyId': accessKeyId,
        'accessKeySecret': accessKeySecret,
        'bucket': bucket,
        'region': region,
      };

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
          key: 'accessKeyId',
          label: 'Access Key ID',
          value: accessKeyId,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'accessKeySecret',
          label: 'Access Key Secret',
          value: accessKeySecret,
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
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'accessKeyId':
        accessKeyId = value;
      case 'accessKeySecret':
        accessKeySecret = value;
      case 'bucket':
        bucket = value;
      case 'region':
        region = value;
    }
  }

  static EngineConfig fromJson(Map<String, dynamic> json) {
    return AliyunConfig(
      accessKeyId: json['accessKeyId'] ?? '',
      accessKeySecret: json['accessKeySecret'] ?? '',
      bucket: json['bucket'] ?? '',
      region: json['region'] ?? '',
    );
  }
}