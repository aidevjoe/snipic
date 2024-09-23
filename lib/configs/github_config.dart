import '../core/config_field.dart';
import 'engine_config.dart';

class GitHubConfig implements EngineConfig {
  String token;
  String owner;
  String repo;
  String branch;
  String path;
  @override
  bool isShowConfigOptions;

  GitHubConfig({
    required this.token,
    required this.owner,
    required this.repo,
    required this.branch,
    required this.path,
    this.isShowConfigOptions = true,
  });

  @override
  String get engineName => 'GitHub';

  @override
  String get engineIcon => 'assets/github_icon.png';

  @override
  bool get isSupportDelete => true;

  @override
  bool get isSupportGetUploadedImages => true;

  @override
  bool isValid() =>
      token.isNotEmpty &&
      owner.isNotEmpty &&
      repo.isNotEmpty &&
      branch.isNotEmpty &&
      path.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'github',
        'token': token,
        'owner': owner,
        'repo': repo,
        'branch': branch,
        'path': path,
      };

  @override
  List<ConfigField> getConfigFields() {
    return [
      ConfigField(
          key: 'token',
          label: 'Personal Access Token',
          value: token,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'owner',
          label: 'Repository Owner',
          value: owner,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'repo',
          label: 'Repository Name',
          value: repo,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'branch',
          label: 'Branch',
          value: branch,
          type: ConfigFieldType.text),
      ConfigField(
          key: 'path',
          label: 'Path in Repository',
          value: path,
          type: ConfigFieldType.text),
    ];
  }

  @override
  void updateField(String key, dynamic value) {
    switch (key) {
      case 'token':
        token = value;
      case 'owner':
        owner = value;
      case 'repo':
        repo = value;
      case 'branch':
        branch = value;
      case 'path':
        path = value;
    }
  }

  static EngineConfig fromJson(Map<String, dynamic> json) {
    return GitHubConfig(
      token: json['token'] ?? '',
      owner: json['owner'] ?? '',
      repo: json['repo'] ?? '',
      branch: json['branch'] ?? 'main',
      path: json['path'] ?? '',
    );
  }
}