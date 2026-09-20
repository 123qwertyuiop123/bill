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
  UuidVersion version = UuidVersion.v4;
  List<String> values = const [];
  String? error;

  void _generate() {
    final result = generateUuidBatch(count, version: version);
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
        SegmentedButton<UuidVersion>(
          segments: const [
            ButtonSegment(value: UuidVersion.v4, label: Text('UUID v4')),
            ButtonSegment(value: UuidVersion.v7, label: Text('UUID v7')),
          ],
          selected: {version},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            version = selection.first;
            values = const [];
            error = null;
          }),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  version == UuidVersion.v4 ? '安全随机标识符' : '按时间大体排序的标识符',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  version == UuidVersion.v4 ? '使用设备安全随机源生成' : '时间字段与安全随机位组合',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            );
            final compact =
                constraints.maxWidth < 420 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.4;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 12),
                  Align(child: _countControls(context)),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: details),
                _countControls(context),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('generateUuid'),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text(
                '生成结果（${values.length} 个）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
        Text(
          version == UuidVersion.v4
              ? '结果只保留在当前页面，不会上传或自动保存。'
              : 'UUID v7 大致按生成时间排序并暴露毫秒时间，不可用作密码或访问令牌。结果不会上传或自动保存。',
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );

  Widget _countControls(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
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
  );
}
