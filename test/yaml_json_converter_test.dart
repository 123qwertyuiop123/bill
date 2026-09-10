import 'package:bill/tools/yaml_json_converter/yaml_json_converter_logic.dart';
import 'package:bill/tools/yaml_json_converter/yaml_json_converter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts YAML and JSON in both directions', () {
    final json = convertYamlJson(
      'name: ZM\nitems:\n  - 1\n  - 2',
      YamlJsonMode.yamlToJson,
    );
    expect(json.isSuccess, isTrue);
    expect(json.output, contains('"name": "ZM"'));

    final yaml = convertYamlJson(
      '{"name":"ZM","items":[1,2]}',
      YamlJsonMode.jsonToYaml,
    );
    expect(yaml.isSuccess, isTrue);
    expect(yaml.output, contains('name: "ZM"'));
    expect(yaml.output, contains('- 2'));
  });

  test('rejects empty, invalid and non-string YAML keys', () {
    expect(convertYamlJson('', YamlJsonMode.yamlToJson).isSuccess, isFalse);
    expect(convertYamlJson('{', YamlJsonMode.jsonToYaml).isSuccess, isFalse);
    expect(
      convertYamlJson('1: value', YamlJsonMode.yamlToJson).isSuccess,
      isFalse,
    );
    expect(
      convertYamlJson('value: !custom data', YamlJsonMode.yamlToJson).isSuccess,
      isFalse,
    );
    expect(
      convertYamlJson(
        'value: "allowed ! text"',
        YamlJsonMode.yamlToJson,
      ).isSuccess,
      isTrue,
    );
  });

  test('enforces input and nesting boundaries', () {
    final oversized = '中' * (maxYamlJsonInputBytes ~/ 3 + 1);
    expect(
      convertYamlJson(oversized, YamlJsonMode.yamlToJson).error,
      contains('200 KB'),
    );
    final deep =
        '${List.filled(66, '[').join()}0${List.filled(66, ']').join()}';
    expect(
      convertYamlJson(deep, YamlJsonMode.jsonToYaml).error,
      contains('64'),
    );
  });

  testWidgets('switches mode, preserves input and clears stale output', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: YamlJsonConverterScreen()));
    await tester.enterText(find.byType(TextField), 'user: content');
    await tester.tap(find.byKey(const Key('convertYamlJson')));
    await tester.pump();
    expect(find.textContaining('"user": "content"'), findsOneWidget);
    await tester.tap(find.text('JSON → YAML'));
    await tester.pump();
    expect(find.text('user: content'), findsOneWidget);
    expect(find.text('转换后将在这里显示结果'), findsOneWidget);
  });
}
