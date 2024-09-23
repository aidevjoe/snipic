import '../core/config_field.dart';
import 'engine_config.dart';

class QiniuConfig implements EngineConfig {
  String accessKey;
  String secretKey;
  String bucket;
  String domain;
  String region;
  @override
  bool isShowConfigOptions;
  String? lastMarker;

  QiniuConfig({
    required this.accessKey,
    required this.secretKey,
    required this.bucket,
    required this.domain,
    this.region = "https://up-z2.qiniup.com",
    this.isShowConfigOptions = true,
  });

  @override
  String get engineName => 'Qiniu';

  @override
  String get engineIcon => 'assets/qiniu_icon.png';

  @override
  bool get isSupportDelete => true;

  @override
  bool get isSupportGetUploadedImages => true;

  @override
  bool isValid() =>
      accessKey.isNotEmpty &&
      secretKey.isNotEmpty &&
      bucket.isNotEmpty &&
      domain.isNotEmpty &&
      region.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'qiniu',
        'accessKey': accessKey,
        'secretKey': secretKey,
        'bucket': bucket,
        'domain': domain,
        'region': region,
      };

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
          key: 'accessKey',
          label: 'Access Key',
          value: accessKey,
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
          key: 'domain',
          label: 'Domain',
          value: domain,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'region',
          label: 'Region',
          value: region,
          type: ConfigFieldType.select,
          options: [
            // https://developer.qiniu.com/kodo/1671/region-endpoint-fq
            "https://up-z0.qiniup.com",
            "https://up-cn-east-2.qiniup.com",
            "https://up-z1.qiniup.com",
            "https://up-z2.qiniup.com",
            "https://up-na0.qiniup.com",
            "https://up-as0.qiniup.com",
            "https://up-ap-southeast-2.qiniup.com",
            "https://up-ap-southeast-3.qiniup.com",
          ].map((e) => ConfigFieldOption(label: e, value: e)).toList()),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'accessKey':
        accessKey = value;
      case 'secretKey':
        secretKey = value;
      case 'bucket':
        bucket = value;
      case 'domain':
        domain = value;
      case 'region':
        region = value;
    }
  }

  static EngineConfig fromJson(Map<String, dynamic> json) {
    return QiniuConfig(
      accessKey: json['accessKey'] ?? '',
      secretKey: json['secretKey'] ?? '',
      bucket: json['bucket'] ?? '',
      domain: json['domain'] ?? '',
      region: json['region'] ?? '',
    );
  }
}
