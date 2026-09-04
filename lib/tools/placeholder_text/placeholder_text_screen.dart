import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../app/widgets/tool_result_widgets.dart';
import 'placeholder_text_logic.dart';

class PlaceholderTextScreen extends StatefulWidget {
  const PlaceholderTextScreen({super.key});
  @override
  State<PlaceholderTextScreen> createState() => _PlaceholderTextScreenState();
}

class _PlaceholderTextScreenState extends State<PlaceholderTextScreen> {
  final _paragraphs = TextEditingController(text: '3');
  final _sentences = TextEditingController(text: '2');
  final _form = GlobalKey<FormState>();
  var _language = PlaceholderLanguage.chinese;
  String _output = '';

  String? _validate(String? text, int max, String label) {
    // 先限制长度与字符，再解析数值，避免大段粘贴进入数值解析。
    if (text == null ||
        text.isEmpty ||
        text.length > 2 ||
        text.codeUnits.any((c) => c < 48 || c > 57)) {
      return '$label请输入 1–$max 的整数';
    }
    final value = int.tryParse(text);
    return value == null || value < 1 || value > max
        ? '$label请输入 1–$max 的整数'
        : null;
  }

  void _generate() {
    if (!_form.currentState!.validate()) return;
    setState(
      () => _output = generatePlaceholderText(
        int.parse(_paragraphs.text),
        int.parse(_sentences.text),
        _language,
      ),
    );
  }

  @override
  void dispose() {
    _paragraphs.dispose();
    _sentences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '占位文本',
    child: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('为排版与测试生成示例内容'),
          const SizedBox(height: 16),
          SegmentedButton<PlaceholderLanguage>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: PlaceholderLanguage.chinese,
                label: Text('中文示例'),
              ),
              ButtonSegment(
                value: PlaceholderLanguage.latin,
                label: Text('拉丁占位文'),
              ),
            ],
            selected: {_language},
            onSelectionChanged: (values) => setState(() {
              _language = values.first;
              _output = '';
            }),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paragraphs,
            key: const Key('paragraphs'),
            keyboardType: TextInputType.number,
            maxLength: 2,
            // 超长输入交由校验报错，不将 100 静默截成 10。
            maxLengthEnforcement: MaxLengthEnforcement.none,
            decoration: const InputDecoration(
              labelText: '段落数量',
              errorMaxLines: 3,
            ),
            validator: (v) => _validate(v, 20, '段落数量'),
            onChanged: (_) => setState(() => _output = ''),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sentences,
            key: const Key('sentences'),
            keyboardType: TextInputType.number,
            maxLength: 2,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            decoration: const InputDecoration(
              labelText: '每段句数',
              errorMaxLines: 3,
            ),
            validator: (v) => _validate(v, 10, '每段句数'),
            onChanged: (_) => setState(() => _output = ''),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _generate, child: const Text('生成文本')),
          const SizedBox(height: 16),
          if (_output.isEmpty)
            const Text('选择数量后点击“生成文本”')
          else
            ToolResultCard(values: {'生成结果': _output}),
          const SizedBox(height: 12),
          CopyResultButton(text: _output),
          const SizedBox(height: 12),
          const Text('仅生成示例，不保存输入'),
        ],
      ),
    ),
  );
}
