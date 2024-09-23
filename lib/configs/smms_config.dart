import 'engine_config.dart';
import '../core/config_field.dart';

// https://imgur.com/account/settings/apps
class SmmsConfig implements EngineConfig {
  String apiKey;
  String host;

  SmmsConfig({
    required this.apiKey,
    this.host = 'https://sm.ms',
  });

  @override
  String get engineName => 'SM.MS';

  @override
  String get engineIcon => 'assets/smms_icon.png';

  @override
  bool get isSupportDelete => true;

  @override
  bool get isSupportGetUploadedImages => true;

  @override
  bool get isShowConfigOptions => true;

  @override
  bool isValid() => apiKey.isNotEmpty && host.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'smms',
        'apiKey': apiKey,
        'host': host,
      };

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
          key: 'apiKey',
          label: 'API Key',
          value: apiKey,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'host',
          label: 'Host',
          value: host,
          type: ConfigFieldType.select,
          options: ['https://sm.ms', 'https://smms.app']
              .map((e) => ConfigFieldOption(label: e, value: e))
              .toList()),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'apiKey':
        apiKey = value;
        break;
      case 'host':
        host = value;
        break;
    }
  }

  factory SmmsConfig.fromJson(Map<String, dynamic> json) {
    return SmmsConfig(
      apiKey: json['apiKey'] ?? '',
      host: json['host'] ?? 'https://sm.ms',
    );
  }
}
