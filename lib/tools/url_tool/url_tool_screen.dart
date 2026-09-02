import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'url_tool_logic.dart';

class UrlToolScreen extends StatefulWidget {
  const UrlToolScreen({super.key});

  @override
  State<UrlToolScreen> createState() => _UrlToolScreenState();
}

class _UrlToolScreenState extends State<UrlToolScreen> {
  final inputController = TextEditingController(
    text: 'https://example.com/search?q=工具箱&page=1&page=2',
  );
  final outputController = TextEditingController();
  UrlToolMode mode = UrlToolMode.query;
  String? error;

  @override
  void dispose() {
    inputController.dispose();
    outputController.dispose();
    super.dispose();
  }

  void _process() {
    final result = processUrlText(inputController.text, mode);
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

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'URL 编解码',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<UrlToolMode>(
          segments: const [
            ButtonSegment(value: UrlToolMode.encode, label: Text('编码')),
            ButtonSegment(value: UrlToolMode.decode, label: Text('解码')),
            ButtonSegment(value: UrlToolMode.query, label: Text('参数解析')),
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
          key: const Key('urlInput'),
          controller: inputController,
          minLines: 5,
          maxLines: 9,
          maxLength: maxUrlToolInputLength,
          decoration: InputDecoration(
            labelText: mode == UrlToolMode.query ? 'URL 或查询参数' : '输入',
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
          key: const Key('urlOutput'),
          controller: outputController,
          readOnly: true,
          minLines: 5,
          maxLines: 10,
          decoration: InputDecoration(
            labelText: mode == UrlToolMode.query ? '参数结果' : '输出',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _process, child: const Text('处理')),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: outputController.text.isEmpty ? null : _copy,
          icon: const Icon(Icons.copy_outlined),
          label: const Text('复制结果'),
        ),
        const SizedBox(height: 8),
        const Text(
          '只在本机处理文本，不会打开或请求输入的网址。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
