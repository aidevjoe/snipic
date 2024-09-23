import '../core/config_field.dart';
import 'engine_config.dart';

enum TokenType {
  anonymous,
  authenticated;

  String get title {
    switch (this) {
      case TokenType.anonymous:
        return "Anonymous";
      case TokenType.authenticated:
        return "Authenticated";
    }
  }
}

class ImgurConfig implements EngineConfig {
  String clientId;
  String? clientSecret;
  String? accessToken;
  String? refreshToken;
  DateTime? tokenExpirationTime;
  bool isAnonymous; // 新增字段

  @override
  bool isShowConfigOptions;

  ImgurConfig({
    required this.clientId,
    this.clientSecret,
    this.accessToken,
    this.refreshToken,
    this.isShowConfigOptions = true,
    this.tokenExpirationTime,
    this.isAnonymous = false, // 默认为非匿名模式
  });

  @override
  String get engineName => 'Imgur';

  @override
  String get engineIcon => 'assets/imgur_icon.png';

  @override
  bool get isSupportDelete => !isAnonymous; // 匿名模式下不支持删除

  @override
  bool get isSupportGetUploadedImages => !isAnonymous; // 匿名模式下不支持获取已上传图片

  @override
  bool isValid() =>
      clientId.isNotEmpty &&
      (isAnonymous ||
          ((clientSecret ?? '').isNotEmpty && (refreshToken ?? '').isNotEmpty));

  void updateToken(String accessToken, String refreshToken, int expiresIn) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    tokenExpirationTime = DateTime.now().add(Duration(seconds: expiresIn));
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'imgur',
        'clientId': clientId,
        'clientSecret': clientSecret,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'isAnonymous': isAnonymous,
        'isShowConfigOptions': isShowConfigOptions
      };

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
        key: 'isAnonymous',
        label: 'Upload Mode',
        value: isAnonymous
            ? TokenType.anonymous.name
            : TokenType.authenticated.name,
        type: ConfigFieldType.select,
        options: TokenType.values
            .map((e) => ConfigFieldOption(label: e.title, value: e.name))
            .toList(),
      ),
      ConfigField(
        key: 'clientId',
        label: 'Client ID',
        value: clientId,
        type: ConfigFieldType.text,
      ),
      if (!isAnonymous) ...[
        ConfigField(
          key: 'clientSecret',
          label: 'Client Secret',
          value: clientSecret,
          type: ConfigFieldType.text,
        ),
        ConfigField(
          key: 'refreshToken',
          label: 'Refresh Token',
          value: refreshToken,
          type: ConfigFieldType.text,
        ),
      ],
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'isAnonymous':
        isAnonymous = value == TokenType.anonymous.name;
        break;
      case 'clientId':
        clientId = value;
        break;
      case 'clientSecret':
        clientSecret = value;
        break;
      case 'refreshToken':
        refreshToken = value;
        break;
    }
  }

  static EngineConfig fromJson(Map<String, dynamic> json) {
    return ImgurConfig(
      clientId: json['clientId'] ?? '',
      clientSecret: json['clientSecret'] ?? '',
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'] ?? '',
      isAnonymous: json['isAnonymous'] ?? false,
      isShowConfigOptions: json['isShowConfigOptions'] ?? true,
    );
  }
}
