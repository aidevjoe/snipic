import '../core/config_field.dart';
import 'engine_config.dart';

class UpyunConfig implements EngineConfig {
  String bucketName;
  String operatorName;
  String operatorPassword;
  String domain;
  @override
  bool isShowConfigOptions;

  UpyunConfig({
    required this.bucketName,
    required this.operatorName,
    required this.operatorPassword,
    required this.domain,
    this.isShowConfigOptions = true,
  });

  @override
  String get engineName => 'Upyun';

  @override
  String get engineIcon => 'assets/upyun_icon.png';

  @override
  bool get isSupportDelete => false;

  @override
  bool get isSupportGetUploadedImages => false;

  @override
  bool isValid() =>
      bucketName.isNotEmpty &&
      operatorName.isNotEmpty &&
      operatorPassword.isNotEmpty &&
      domain.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'upyun',
        'bucketName': bucketName,
        'operatorName': operatorName,
        'operatorPassword': operatorPassword,
        'domain': domain,
      };

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
          key: 'bucketName',
          label: 'Bucket Name',
          value: bucketName,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'operatorName',
          label: 'Operator Name',
          value: operatorName,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'operatorPassword',
          label: 'Operator Password',
          value: operatorPassword,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'domain',
          label: 'Custom Domain',
          value: domain,
          type: ConfigFieldType.text),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'bucketName':
        bucketName = value;
      case 'operatorName':
        operatorName = value;
      case 'operatorPassword':
        operatorPassword = value;
      case 'domain':
        domain = value;
    }
  }

  static EngineConfig fromJson(Map<String, dynamic> json) {
    return UpyunConfig(
      bucketName: json['bucketName'] ?? '',
      operatorName: json['operatorName'] ?? '',
      operatorPassword: json['operatorPassword'] ?? '',
      domain: json['domain'] ?? '',
    );
  }
}
