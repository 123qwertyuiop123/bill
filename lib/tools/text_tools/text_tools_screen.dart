import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';

class TextToolsScreen extends StatefulWidget {
  const TextToolsScreen({super.key});

  @override
  State<TextToolsScreen> createState() => _TextToolsScreenState();
}

class _TextToolsScreenState extends State<TextToolsScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  int get characters => controller.text.runes.length;
  int get lines =>
      controller.text.isEmpty ? 0 : '\n'.allMatches(controller.text).length + 1;
  int get words => controller.text.trim().isEmpty
      ? 0
      : controller.text.trim().split(RegExp(r'\s+')).length;

  void _change(String Function(String) transform) {
    final text = transform(controller.text);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '文本工具',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          minLines: 8,
          maxLines: 16,
          maxLength: 20000,
          decoration: const InputDecoration(
            hintText: '在这里输入或粘贴文本…',
            alignLabelWithHint: true,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('$characters 字符')),
            Chip(label: Text('$words 单词')),
            Chip(label: Text('$lines 行')),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => _change((value) => value.toUpperCase()),
              child: const Text('转大写'),
            ),
            OutlinedButton(
              onPressed: () => _change((value) => value.toLowerCase()),
              child: const Text('转小写'),
            ),
            OutlinedButton(
              onPressed: () => _change(
                (value) => value
                    .split('\n')
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty)
                    .join('\n'),
              ),
              child: const Text('清理空行'),
            ),
            OutlinedButton.icon(
              onPressed: controller.text.isEmpty
                  ? null
                  : () =>
                        Clipboard.setData(ClipboardData(text: controller.text)),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('复制'),
            ),
            TextButton(
              onPressed: controller.text.isEmpty
                  ? null
                  : () {
                      controller.clear();
                      setState(() {});
                    },
              child: const Text('清空'),
            ),
          ],
        ),
      ],
    ),
  );
}
