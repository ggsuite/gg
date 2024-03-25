import 'dart:convert';

import 'package:yaml_edit/yaml_edit.dart';

void main() {
  const jsonString = r'''
{
  "key": "value",
  "list": [
    "first",
    "second",
    "last entry in the list"
  ],
  "map": {
    "multiline": "this is a fairly long string with\nline breaks..."
  }
}
''';
  final jsonValue = json.decode(jsonString);

  // Convert jsonValue to YAML
  final yamlEditor = YamlEditor('');
  yamlEditor.update([], jsonValue);

  final root = yamlEditor.parseAt([]);

  print(yamlEditor.toString());
  print(json.encode(root));

  final YamlEditor yamlEditor2 = YamlEditor('');
  yamlEditor2.update([], root);
}
