import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'list_processor_logic.dart';

class ListProcessorScreen extends StatefulWidget {
  const ListProcessorScreen({super.key});

  @override
  State<ListProcessorScreen> createState() => _ListProcessorScreenState();
}

class _ListProcessorScreenState extends State<ListProcessorScreen> {
  final controller = TextEditingController(text: '苹果, 香蕉, 苹果, 西瓜');
  List<String> result = const [];
  String operation = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _process(String name) {
    final source = parseList(controller.text);
    setState(() {
      operation = name;
      result = switch (name) {
        '排序' => sortList(source),
        '去重' => uniqueList(source),
        '打乱' => shuffleList(source),
        _ => source,
      };
    });
  }

  Future<void> _copy() async {
    if (result.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: result.join('\n')));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('处理结果已复制')));
    }
  }

  void _replace() {
    if (result.isEmpty) return;
    final text = result.join('\n');
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '列表处理',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: controller,
          minLines: 5,
          maxLines: 10,
          maxLength: 50000,
          decoration: const InputDecoration(
            labelText: '原始列表',
            helperText: '每行或用逗号分隔，最多 1000 项',
          ),
        ),
        const SizedBox(height: 12),
        const Text('操作', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['排序', '去重', '打乱', '清理空行']
              .map(
                (name) => ChoiceChip(
                  label: Text(name),
                  selected: operation == name,
                  onSelected: (_) => _process(name),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 180, maxHeight: 320),
            child: result.isEmpty
                ? const Center(
                    child: Text(
                      '选择一种操作查看结果',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: result.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        ListTile(dense: true, title: Text(result[index])),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: result.isEmpty ? null : _copy,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('复制'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: result.isEmpty ? null : _replace,
                child: const Text('替换原文'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
