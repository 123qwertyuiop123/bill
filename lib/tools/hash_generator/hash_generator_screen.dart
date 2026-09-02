import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'hash_generator_logic.dart';

class HashGeneratorScreen extends StatefulWidget {
  const HashGeneratorScreen({super.key});

  @override
  State<HashGeneratorScreen> createState() => _HashGeneratorScreenState();
}

class _HashGeneratorScreenState extends State<HashGeneratorScreen> {
  final inputController = TextEditingController(text: 'ZM工具箱');
  final outputController = TextEditingController();
  HashAlgorithm algorithm = HashAlgorithm.sha256;
  String? error;

  @override
  void dispose() {
    inputController.dispose();
    outputController.dispose();
    super.dispose();
  }

  void _generate() {
    final result = generateTextHash(inputController.text, algorithm);
    setState(() {
      error = result.error;
      outputController.text = result.digest;
    });
  }

  Future<void> _copy() async {
    if (outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('哈希结果已复制')));
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '哈希生成',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<HashAlgorithm>(
            segments: [
              for (final item in HashAlgorithm.values)
                ButtonSegment(value: item, label: Text(item.label)),
            ],
            selected: {algorithm},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => setState(() {
              algorithm = selection.first;
              error = null;
              outputController.clear();
            }),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('hashInput'),
          controller: inputController,
          minLines: 7,
          maxLines: 12,
          maxLength: maxHashInputLength,
          decoration: const InputDecoration(
            labelText: '输入文本',
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
        FilledButton(onPressed: _generate, child: const Text('生成哈希')),
        const SizedBox(height: 16),
        TextField(
          key: const Key('hashOutput'),
          controller: outputController,
          readOnly: true,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            labelText: '哈希结果',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: outputController.text.isEmpty ? null : _copy,
          icon: const Icon(Icons.copy_outlined),
          label: const Text('复制结果'),
        ),
        const SizedBox(height: 8),
        Text(
          algorithm == HashAlgorithm.md5 || algorithm == HashAlgorithm.sha1
              ? '${algorithm.label} 仅用于兼容校验，不适合安全用途或密码存储。'
              : '仅在本机计算；哈希是单向摘要，不会保存输入。',
          style: TextStyle(
            color:
                algorithm == HashAlgorithm.md5 ||
                    algorithm == HashAlgorithm.sha1
                ? AppColors.danger
                : AppColors.muted,
          ),
        ),
      ],
    ),
  );
}
