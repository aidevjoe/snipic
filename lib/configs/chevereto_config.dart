import '../core/config_field.dart';
import 'engine_config.dart';

class CheveretoConfig implements EngineConfig {
  String apiUrl;
  String apiKey;
  @override
  bool isShowConfigOptions;

  CheveretoConfig(
      {required this.apiUrl,
      required this.apiKey,
      this.isShowConfigOptions = true});

  @override
  String get engineName => 'Chevereto';

  @override
  String get engineIcon => 'assets/chevereto_icon.png';

  @override
  bool get isSupportDelete => false;

  @override
  bool get isSupportGetUploadedImages => false;

  @override
  bool isValid() => apiUrl.isNotEmpty && apiKey.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'chevereto',
        'apiUrl': apiUrl,
        'apiKey': apiKey,
        'isShowConfigOptions': isShowConfigOptions
      };

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
          key: 'apiUrl',
          label: 'API URL',
          value: apiUrl,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'apiKey',
          label: 'API Key',
          value: apiKey,
          type: ConfigFieldType.text),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'apiUrl':
        apiUrl = value;
        break;
      case 'apiKey':
        apiKey = value;
        break;
    }
  }

  static EngineConfig fromJson(Map<String, dynamic> json) {
    return CheveretoConfig(
        apiUrl: json['apiUrl'] ?? '',
        apiKey: json['apiKey'] ?? '',
        isShowConfigOptions: json['isShowConfigOptions'] ?? true);
  }
}
