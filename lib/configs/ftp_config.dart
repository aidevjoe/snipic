import '../core/config_field.dart';
import 'engine_config.dart';

class FTPConfig implements EngineConfig {
  String host;
  int port;
  String username;
  String password;
  String basePath;
  String? customDomain;
  bool useSFTP;
  @override
  bool isShowConfigOptions;

  FTPConfig({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.basePath,
    this.customDomain,
    this.useSFTP = false,
    this.isShowConfigOptions = true,
  });

  @override
  String get engineName => useSFTP ? 'SFTP' : 'FTP';

  @override
  String get engineIcon => useSFTP ? 'assets/sftp_icon.png' : 'assets/ftp_icon.png';

  @override
  bool get isSupportDelete => true;

  @override
  bool get isSupportGetUploadedImages => true;

  @override
  bool isValid() =>
      host.isNotEmpty &&
      port > 0 &&
      username.isNotEmpty &&
      password.isNotEmpty &&
      basePath.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': useSFTP ? 'sftp' : 'ftp',
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'basePath': basePath,
        'customDomain': customDomain,
        'useSFTP': useSFTP,
      };

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
          key: 'host',
          label: 'Host',
          value: host,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'port',
          label: 'Port',
          value: port.toString(),
          type: ConfigFieldType.number),
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
      ConfigField(
          key: 'useSFTP',
          label: 'Use SFTP',
          value: useSFTP,
          type: ConfigFieldType.boolean),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'host':
        host = value;
      case 'port':
        port = int.parse(value);
      case 'username':
        username = value;
      case 'password':
        password = value;
      case 'basePath':
        basePath = value;
      case 'customDomain':
        customDomain = value.isEmpty ? null : value;
      case 'useSFTP':
        useSFTP = value;
    }
  }

  static EngineConfig fromJson(Map<String, dynamic> json) {
    return FTPConfig(
      host: json['host'] ?? '',
      port: json['port'] ?? 21,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      basePath: json['basePath'] ?? '',
      customDomain: json['customDomain'],
      useSFTP: json['useSFTP'] ?? false,
    );
  }
}