import 'package:flutter/material.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'text_diff_logic.dart';

class TextDiffScreen extends StatefulWidget {
  const TextDiffScreen({super.key});

  @override
  State<TextDiffScreen> createState() => _TextDiffScreenState();
}

class _TextDiffScreenState extends State<TextDiffScreen> {
  final originalController = TextEditingController(
    text: '今天天气很好\n我们去公园散步吧\n带上相机\n拍些照片\n开心的一天',
  );
  final updatedController = TextEditingController(
    text: '今天天气很好\n我们去海边散步吧\n带上相机\n拍很多照片\n开心的一天',
  );
  List<DiffLine> result = const [];

  @override
  void dispose() {
    originalController.dispose();
    updatedController.dispose();
    super.dispose();
  }

  void _compare() {
    if (originalController.text.length > 10000 ||
        updatedController.text.length > 10000) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('每段文本不能超过 10000 个字符')));
      return;
    }
    setState(
      () => result = diffLines(originalController.text, updatedController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final added = result.where((line) => line.type == DiffType.added).length;
    final removed = result
        .where((line) => line.type == DiffType.removed)
        .length;
    final unchanged = result
        .where((line) => line.type == DiffType.unchanged)
        .length;
    return ToolPageScaffold(
      title: '文本对比',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 700
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _input(originalController, '原文本')),
                      const SizedBox(width: 12),
                      Expanded(child: _input(updatedController, '新文本')),
                    ],
                  )
                : Column(
                    children: [
                      _input(originalController, '原文本'),
                      const SizedBox(height: 12),
                      _input(updatedController, '新文本'),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _compare,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('开始对比'),
          ),
          const SizedBox(height: 16),
          if (result.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('新增 $added')),
                Chip(label: Text('删除 $removed')),
                Chip(label: Text('未变 $unchanged')),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: result.length,
                itemBuilder: (context, index) {
                  final line = result[index];
                  final prefix = switch (line.type) {
                    DiffType.added => '+',
                    DiffType.removed => '−',
                    DiffType.unchanged => ' ',
                  };
                  final color = switch (line.type) {
                    DiffType.added => AppColors.selected,
                    DiffType.removed => const Color(0xffffe8e8),
                    DiffType.unchanged => Colors.transparent,
                  };
                  final textColor = line.type == DiffType.removed
                      ? AppColors.danger
                      : AppColors.ink;
                  return Container(
                    color: color,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text(
                            prefix,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line.text,
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _input(TextEditingController controller, String label) => TextField(
    controller: controller,
    minLines: 5,
    maxLines: 8,
    maxLength: 10000,
    decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
  );
}
