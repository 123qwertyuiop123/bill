import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'xml_tool_logic.dart';

class XmlToolScreen extends StatefulWidget {
  const XmlToolScreen({super.key});

  @override
  State<XmlToolScreen> createState() => _XmlToolScreenState();
}

class _XmlToolScreenState extends State<XmlToolScreen> {
  final _input = TextEditingController(text: '<note><title>提醒</title></note>');
  XmlToolMode _mode = XmlToolMode.format;
  XmlToolResult? _result;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _process() => setState(() => _result = processXml(_input.text, _mode));

  String get _buttonText => switch (_mode) {
    XmlToolMode.format => '格式化 XML',
    XmlToolMode.minify => '压缩 XML',
    XmlToolMode.validate => '校验 XML',
  };

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'XML 工具',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<XmlToolMode>(
          segments: const [
            ButtonSegment(value: XmlToolMode.format, label: Text('格式化')),
            ButtonSegment(value: XmlToolMode.minify, label: Text('压缩')),
            ButtonSegment(value: XmlToolMode.validate, label: Text('校验')),
          ],
          selected: {_mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            _mode = selection.first;
            _result = null;
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('xmlInput'),
          controller: _input,
          minLines: 7,
          maxLines: 12,
          maxLength: maxXmlInputCharacters,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'XML 内容',
            alignLabelWithHint: true,
            errorText: _result?.error,
            errorMaxLines: 3,
          ),
          onChanged: (_) => setState(() => _result = null),
        ),
        FilledButton(
          key: const Key('processXml'),
          onPressed: _process,
          child: Text(_buttonText),
        ),
        if (_result case final result? when result.isSuccess) ...[
          const SizedBox(height: 16),
          ToolResultCard(
            values: {'状态': '格式正确', '元素数量': '${result.elementCount} 个'},
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(result.output),
          ),
          const SizedBox(height: 8),
          CopyResultButton(text: result.output),
        ],
        const SizedBox(height: 12),
        const Text(
          '最大 200 KB · 不支持 DTD、外部实体或网络资源',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
