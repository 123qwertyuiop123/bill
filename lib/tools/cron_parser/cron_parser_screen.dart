import 'package:flutter/material.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'cron_parser_logic.dart';
import 'cron_parser_service.dart';

typedef CronRunner = Future<CronParseResult> Function(String input);

class CronParserScreen extends StatefulWidget {
  const CronParserScreen({super.key, this.runner = parseCronSafely});

  final CronRunner runner;

  @override
  State<CronParserScreen> createState() => _CronParserScreenState();
}

class _CronParserScreenState extends State<CronParserScreen> {
  final inputController = TextEditingController(text: '0 9 * * 1-5');
  CronParseResult? result;
  bool isRunning = false;

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    if (isRunning) return;
    setState(() => isRunning = true);
    final next = await widget.runner(inputController.text);
    if (!mounted) return;
    setState(() {
      result = next;
      isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'Cron 解析',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          key: const Key('cronInput'),
          controller: inputController,
          maxLength: maxCronInputLength,
          decoration: const InputDecoration(
            labelText: 'Cron 表达式',
            helperText: '分钟 小时 日期 月份 星期，例如：0 9 * * 1-5',
          ),
        ),
        if (result?.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              result!.error!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        FilledButton(
          onPressed: isRunning ? null : _parse,
          child: Text(isRunning ? '解析中…' : '解析'),
        ),
        if (result?.isSuccess ?? false) ...[
          const SizedBox(height: 18),
          Text('含义', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                result!.description,
                key: const Key('cronDescription'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('接下来 5 次执行', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              key: const Key('cronNextRuns'),
              children: [
                for (
                  var index = 0;
                  index < result!.nextRuns.length;
                  index++
                ) ...[
                  ListTile(
                    title: Text(formatCronDateTime(result!.nextRuns[index])),
                  ),
                  if (index < result!.nextRuns.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          '按设备本地时区计算；不创建系统定时任务。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
