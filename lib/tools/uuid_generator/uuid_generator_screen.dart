import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'uuid_generator_logic.dart';

class UuidGeneratorScreen extends StatefulWidget {
  const UuidGeneratorScreen({super.key});

  @override
  State<UuidGeneratorScreen> createState() => _UuidGeneratorScreenState();
}

class _UuidGeneratorScreenState extends State<UuidGeneratorScreen> {
  int count = 5;
  List<String> values = const [];
  String? error;

  void _generate() {
    final result = generateUuidBatch(count);
    setState(() {
      values = result.values;
      error = result.error;
    });
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('UUID 已复制')));
  }

  Future<void> _copyAll() async {
    if (values.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: values.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('全部 UUID 已复制')));
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'UUID 生成',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UUID v4',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '使用设备安全随机源生成',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: '减少数量',
              onPressed: count > minUuidBatchSize
                  ? () => setState(() => count--)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton.filledTonal(
              tooltip: '增加数量',
              onPressed: count < maxUuidBatchSize
                  ? () => setState(() => count++)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.autorenew),
          label: const Text('生成 UUID'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        if (values.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Text('生成结果', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: _copyAll,
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('复制全部'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < values.length; index++)
            Card(
              key: Key('uuidOutput$index'),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: SelectableText(values[index]),
                trailing: IconButton(
                  tooltip: '复制',
                  onPressed: () => _copy(values[index]),
                  icon: const Icon(Icons.copy_outlined),
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),
        const Text(
          '结果只保留在当前页面，不会上传或自动保存。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
