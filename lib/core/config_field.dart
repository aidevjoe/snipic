enum ConfigFieldType { text, number, boolean, select, slider }

class ConfigField {
  final String key;
  final String label;
  final dynamic value;
  final ConfigFieldType type;
  final List<ConfigFieldOption>? options;

  final num? min;
  final num? max;

  ConfigField({
    required this.key,
    required this.label,
    required this.value,
    required this.type,
    this.options,
    this.min,
    this.max,
  });
}

class ConfigFieldOption {
  final String label;
  final dynamic value;

  ConfigFieldOption({
    required this.label,
    required this.value,
  });
}
