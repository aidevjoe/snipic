import '../core/config_field.dart';
import 'engine_config.dart';

class LskyConfig implements EngineConfig {
  String apiUrl;
  String token;
  String? albumId;
  String? strategyId;
  @override
  bool isShowConfigOptions;

  LskyConfig({
    required this.apiUrl,
    required this.token,
    this.albumId,
    this.strategyId,
    this.isShowConfigOptions = true,
  });

  @override
  String get engineName => 'Lsky Pro';

  @override
  String get engineIcon => 'assets/lsky_icon.png';

  @override
  bool get isSupportDelete => true;

  @override
  bool get isSupportGetUploadedImages => true;

  @override
  bool isValid() => apiUrl.isNotEmpty && token.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'lsky',
        'apiUrl': apiUrl,
        'token': token,
        'albumId': albumId,
        'strategyId': strategyId,
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
          key: 'token',
          label: 'Token',
          value: token,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'albumId',
          label: 'Album ID (optional)',
          value: albumId ?? '',
          type: ConfigFieldType.text),
      ConfigField(
          key: 'strategyId',
          label: 'Strategy ID (optional)',
          value: strategyId ?? '',
          type: ConfigFieldType.text),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'apiUrl':
        apiUrl = value;
      case 'token':
        token = value;
      case 'albumId':
        albumId = value.isEmpty ? null : value;
      case 'strategyId':
        strategyId = value.isEmpty ? null : value;
    }
  }

  static EngineConfig fromJson(Map<String, dynamic> json) {
    return LskyConfig(
      apiUrl: json['apiUrl'] ?? '',
      token: json['token'] ?? '',
      albumId: json['albumId'],
      strategyId: json['strategyId'],
    );
  }
}