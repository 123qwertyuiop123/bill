import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'json_tool_logic.dart';

class JsonToolScreen extends StatefulWidget {
  const JsonToolScreen({super.key});

  @override
  State<JsonToolScreen> createState() => _JsonToolScreenState();
}

class _JsonToolScreenState extends State<JsonToolScreen> {
  final inputController = TextEditingController(
    text: '{"name":"ZM工具箱","version":"1.0.0"}',
  );
  final outputController = TextEditingController();
  JsonToolMode mode = JsonToolMode.format;
  String? error;

  @override
  void dispose() {
    inputController.dispose();
    outputController.dispose();
    super.dispose();
  }

  void _process() {
    final result = processJson(inputController.text, mode);
    setState(() {
      error = result.error;
      outputController.text = result.output;
    });
  }

  Future<void> _copy() async {
    if (outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('结果已复制')));
  }

  void _clear() {
    inputController.clear();
    outputController.clear();
    setState(() => error = null);
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'JSON工具',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<JsonToolMode>(
          segments: const [
            ButtonSegment(value: JsonToolMode.format, label: Text('格式化')),
            ButtonSegment(value: JsonToolMode.minify, label: Text('压缩')),
            ButtonSegment(value: JsonToolMode.validate, label: Text('校验')),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            mode = selection.first;
            error = null;
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('jsonInput'),
          controller: inputController,
          minLines: 7,
          maxLines: 12,
          maxLength: maxJsonInputLength,
          decoration: const InputDecoration(
            labelText: '输入',
            alignLabelWithHint: true,
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        TextField(
          key: const Key('jsonOutput'),
          controller: outputController,
          readOnly: true,
          minLines: 7,
          maxLines: 12,
          decoration: const InputDecoration(
            labelText: '结果',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _process, child: const Text('处理')),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: outputController.text.isEmpty ? null : _copy,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('复制结果'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextButton(onPressed: _clear, child: const Text('清空')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('内容仅在本机解析，不会上传。', style: TextStyle(color: AppColors.muted)),
      ],
    ),
  );
}
