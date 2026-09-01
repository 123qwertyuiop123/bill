import 'package:flutter/material.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'tally_counter_controller.dart';

class TallyCounterScreen extends StatefulWidget {
  const TallyCounterScreen({super.key});

  @override
  State<TallyCounterScreen> createState() => _TallyCounterScreenState();
}

class _TallyCounterScreenState extends State<TallyCounterScreen> {
  late final TallyCounterController controller;

  @override
  void initState() {
    super.initState();
    controller = TallyCounterController()..initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _addCounter() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建计数器'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name == null) return;
    final success = await controller.add(name);
    if (!mounted || success) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('名称不能为空，且不能超过 30 个字符')));
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置计数器？'),
        content: const Text('当前计数将变为 0。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('重置'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '计数器',
    actions: [
      IconButton(
        onPressed: _addCounter,
        tooltip: '新建计数器',
        icon: const Icon(Icons.add),
      ),
    ],
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5),
          );
        }
        final selected = controller.selected!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              elevation: 0,
              child: Column(
                children: [
                  for (final item in controller.counters)
                    ListTile(
                      title: Text(item.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.value}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      selected: item.id == selected.id,
                      selectedTileColor: AppColors.selected,
                      onTap: () => controller.select(item.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      selected.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      child: Text(
                        '${selected.value}',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => controller.change(-1),
                          icon: const Icon(Icons.remove),
                          iconSize: 30,
                        ),
                        TextButton(
                          onPressed: _confirmReset,
                          child: const Text('重置'),
                        ),
                        IconButton.filled(
                          onPressed: () => controller.change(1),
                          icon: const Icon(Icons.add),
                          iconSize: 30,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '计数会自动保存在本机。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        );
      },
    ),
  );
}
