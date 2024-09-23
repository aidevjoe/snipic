import '../core/config_field.dart';
import 'engine_config.dart';

class WebDavConfig implements EngineConfig {
  String serverUrl;
  String username;
  String password;
  String basePath;
  String? customDomain;
  @override
  bool isShowConfigOptions;

  WebDavConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.basePath,
    this.customDomain,
    this.isShowConfigOptions = true,
  });

  @override
  String get engineName => 'WebDAV';

  @override
  String get engineIcon => 'assets/webdav_icon.png';

  @override
  bool get isSupportDelete => true;

  @override
  bool get isSupportGetUploadedImages => true;

  @override
  bool isValid() =>
      serverUrl.isNotEmpty &&
      username.isNotEmpty &&
      password.isNotEmpty &&
      basePath.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'webdav',
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
        'basePath': basePath,
        'customDomain': customDomain,
      };

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
          key: 'serverUrl',
          label: 'Server URL',
          value: serverUrl,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'username',
          label: 'Username',
          value: username,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'password',
          label: 'Password',
          value: password,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'basePath',
          label: 'Base Path',
          value: basePath,
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
      case 'serverUrl':
        serverUrl = value;
      case 'username':
        username = value;
      case 'password':
        password = value;
      case 'basePath':
        basePath = value;
      case 'customDomain':
        customDomain = value.isEmpty ? null : value;
    }
  }

  static EngineConfig fromJson(Map<String, dynamic> json) {
    return WebDavConfig(
      serverUrl: json['serverUrl'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      basePath: json['basePath'] ?? '',
      customDomain: json['customDomain'],
    );
  }
}