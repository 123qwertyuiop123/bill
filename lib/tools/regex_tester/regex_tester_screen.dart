import 'package:flutter/material.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'regex_tester_logic.dart';
import 'regex_tester_service.dart';

typedef RegexRunner = Future<RegexToolResult> Function({
  required String pattern,
  required String text,
  required bool global,
  required bool caseSensitive,
  required bool multiLine,
});

class RegexTesterScreen extends StatefulWidget {
  const RegexTesterScreen({super.key, this.runner = runRegexSafely});

  final RegexRunner runner;

  @override
  State<RegexTesterScreen> createState() => _RegexTesterScreenState();
}

class _RegexTesterScreenState extends State<RegexTesterScreen> {
  final patternController = TextEditingController(text: r'\b[A-Za-z]+\b');
  final textController = TextEditingController(
    text: 'ZM工具箱 supports Regex and offline tools.',
  );
  bool global = true;
  bool ignoreCase = false;
  bool multiLine = false;
  bool isRunning = false;
  RegexToolResult? result;

  @override
  void dispose() {
    patternController.dispose();
    textController.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (isRunning) return;
    setState(() => isRunning = true);
    final next = await widget.runner(
      pattern: patternController.text,
      text: textController.text,
      global: global,
      caseSensitive: !ignoreCase,
      multiLine: multiLine,
    );
    if (!mounted) return;
    setState(() {
      result = next;
      isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '正则测试',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          key: const Key('regexPattern'),
          controller: patternController,
          maxLength: maxRegexPatternLength,
          decoration: const InputDecoration(labelText: '正则表达式'),
        ),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('全局'),
              selected: global,
              onSelected: (value) => setState(() => global = value),
            ),
            FilterChip(
              label: const Text('忽略大小写'),
              selected: ignoreCase,
              onSelected: (value) => setState(() => ignoreCase = value),
            ),
            FilterChip(
              label: const Text('多行'),
              selected: multiLine,
              onSelected: (value) => setState(() => multiLine = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('regexText'),
          controller: textController,
          minLines: 5,
          maxLines: 8,
          maxLength: maxRegexTextLength,
          decoration: const InputDecoration(
            labelText: '测试文本',
            alignLabelWithHint: true,
          ),
        ),
        FilledButton.icon(
          onPressed: isRunning ? null : _run,
          icon: isRunning
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(isRunning ? '匹配中…' : '开始匹配'),
        ),
        const SizedBox(height: 16),
        if (result?.error != null)
          Text(result!.error!, style: const TextStyle(color: AppColors.danger))
        else if (result != null) ...[
          Text(
            '匹配结果（${result!.matches.length}）',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (result!.isTruncated)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '结果过多，仅显示前 500 项',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          const SizedBox(height: 8),
          if (result!.matches.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('没有匹配内容'),
              ),
            )
          else
            SizedBox(
              height: 280,
              child: ListView.builder(
                key: const Key('regexResults'),
                itemCount: result!.matches.length,
                itemBuilder: (context, index) {
                  final item = result!.matches[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.value.isEmpty ? '（空匹配）' : item.value),
                      trailing: Text('位置 ${item.start}-${item.end}'),
                    ),
                  );
                },
              ),
            ),
        ],
        const SizedBox(height: 12),
        const Text(
          '仅在本机运行；复杂表达式超时后会自动停止。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
