import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'yaml_json_converter_logic.dart';

class YamlJsonConverterScreen extends StatefulWidget {
  const YamlJsonConverterScreen({super.key});

  @override
  State<YamlJsonConverterScreen> createState() =>
      _YamlJsonConverterScreenState();
}

class _YamlJsonConverterScreenState extends State<YamlJsonConverterScreen> {
  final _input = TextEditingController(text: 'name: ZM工具箱\noffline: true');
  YamlJsonMode _mode = YamlJsonMode.yamlToJson;
  String _output = '';
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _convert() {
    final result = convertYamlJson(_input.text, _mode);
    setState(() {
      _output = result.output;
      _error = result.error;
    });
  }

  void _changeMode(YamlJsonMode mode) {
    setState(() {
      _mode = mode;
      _output = '';
      _error = null;
      // 切换方向不覆盖用户输入；即使内容暂时不符合新格式，也应允许用户自行编辑。
    });
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'YAML/JSON 转换',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<YamlJsonMode>(
          segments: const [
            ButtonSegment(
              value: YamlJsonMode.yamlToJson,
              label: Text('YAML → JSON'),
            ),
            ButtonSegment(
              value: YamlJsonMode.jsonToYaml,
              label: Text('JSON → YAML'),
            ),
          ],
          selected: {_mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => _changeMode(selection.first),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('yamlJsonInput'),
          controller: _input,
          minLines: 7,
          maxLines: 12,
          maxLength: maxYamlJsonInputCharacters,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: '输入内容',
            alignLabelWithHint: true,
            errorText: _error,
            errorMaxLines: 3,
          ),
          onChanged: (_) => setState(() {
            _output = '';
            _error = null;
          }),
        ),
        FilledButton(
          key: const Key('convertYamlJson'),
          onPressed: _convert,
          child: const Text('开始转换'),
        ),
        const SizedBox(height: 16),
        const Text('转换结果', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(_output.isEmpty ? '转换后将在这里显示结果' : _output),
        ),
        const SizedBox(height: 8),
        CopyResultButton(text: _output),
        const SizedBox(height: 12),
        const Text(
          '最大 200 KB · 内容仅在本机内存中处理',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
