import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'base64_tool_logic.dart';

class Base64ToolScreen extends StatefulWidget {
  const Base64ToolScreen({super.key});

  @override
  State<Base64ToolScreen> createState() => _Base64ToolScreenState();
}

class _Base64ToolScreenState extends State<Base64ToolScreen> {
  final inputController = TextEditingController(text: 'ZM工具箱');
  final outputController = TextEditingController();
  Base64ToolMode mode = Base64ToolMode.encode;
  String? error;

  @override
  void dispose() {
    inputController.dispose();
    outputController.dispose();
    super.dispose();
  }

  void _process() {
    final result = processBase64(inputController.text, mode);
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
    title: 'Base64',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<Base64ToolMode>(
          segments: const [
            ButtonSegment(value: Base64ToolMode.encode, label: Text('编码')),
            ButtonSegment(value: Base64ToolMode.decode, label: Text('解码')),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            mode = selection.first;
            error = null;
            outputController.clear();
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('base64Input'),
          controller: inputController,
          minLines: 7,
          maxLines: 12,
          maxLength: maxBase64InputLength,
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
          key: const Key('base64Output'),
          controller: outputController,
          readOnly: true,
          minLines: 7,
          maxLines: 12,
          decoration: const InputDecoration(
            labelText: '输出',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _process, child: const Text('转换')),
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
        const Text(
          '仅转换 UTF-8 文本，内容不会离开设备。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
