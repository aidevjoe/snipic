import '../core/config_field.dart';
import 'engine_config.dart';

class AWSS3Config implements EngineConfig {
  String accessKeyId;
  String secretAccessKey;
  String bucket;
  String region;
  String? customDomain;
  @override
  bool isShowConfigOptions;

  AWSS3Config({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.bucket,
    required this.region,
    this.customDomain,
    this.isShowConfigOptions = true,
  });

  @override
  String get engineName => 'AWS S3';

  @override
  String get engineIcon => 'assets/aws_s3_icon.png';

  @override
  bool get isSupportDelete => true;

  @override
  bool get isSupportGetUploadedImages => true;

  @override
  bool isValid() =>
      accessKeyId.isNotEmpty &&
      secretAccessKey.isNotEmpty &&
      bucket.isNotEmpty &&
      region.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'aws_s3',
        'accessKeyId': accessKeyId,
        'secretAccessKey': secretAccessKey,
        'bucket': bucket,
        'region': region,
        'customDomain': customDomain,
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
          key: 'secretAccessKey',
          label: 'Secret Access Key',
          value: secretAccessKey,
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
          key: 'customDomain',
          label: 'Custom Domain (optional)',
          value: customDomain ?? '',
          type: ConfigFieldType.text),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'accessKeyId':
        accessKeyId = value;
      case 'secretAccessKey':
        secretAccessKey = value;
      case 'bucket':
        bucket = value;
      case 'region':
        region = value;
      case 'customDomain':
        customDomain = value.isEmpty ? null : value;
    }
  }

  static EngineConfig fromJson(Map<String, dynamic> json) {
    return AWSS3Config(
      accessKeyId: json['accessKeyId'] ?? '',
      secretAccessKey: json['secretAccessKey'] ?? '',
      bucket: json['bucket'] ?? '',
      region: json['region'] ?? '',
      customDomain: json['customDomain'],
    );
  }
}