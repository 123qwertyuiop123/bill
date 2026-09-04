import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'markdown_preview_logic.dart';

class MarkdownPreviewScreen extends StatefulWidget {
  const MarkdownPreviewScreen({super.key});

  @override
  State<MarkdownPreviewScreen> createState() => _MarkdownPreviewScreenState();
}

class _MarkdownPreviewScreenState extends State<MarkdownPreviewScreen> {
  final _input = TextEditingController(
    text: '# 项目说明\n这是一个 **离线预览** 示例。\n- 支持标题与列表\n- 支持代码块',
  );
  MarkdownPreviewResult? _result;
  String? _error;

  void _preview() {
    final result = parseMarkdownPreview(_input.text);
    setState(() {
      _result = result.isSuccess ? result : null;
      _error = result.error;
    });
  }

  Future<void> _copy() async {
    if (_input.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _input.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Markdown 源码已复制')));
  }

  Future<void> _confirmClear() async {
    if (_input.text.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空内容？'),
        content: const Text('当前输入和预览将被清空。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _input.clear();
      _result = null;
      _error = null;
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'Markdown 预览',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('在本机预览 Markdown 排版'),
        const SizedBox(height: 16),
        TextField(
          key: const Key('markdownInput'),
          controller: _input,
          minLines: 7,
          maxLines: 14,
          maxLength: maxMarkdownLength,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          decoration: InputDecoration(
            labelText: 'Markdown 内容',
            alignLabelWithHint: true,
            errorText: _error,
            errorMaxLines: 3,
          ),
          onChanged: (_) => setState(() {
            _result = null;
            _error = null;
          }),
        ),
        FilledButton(
          key: const Key('updateMarkdownPreview'),
          onPressed: _preview,
          child: const Text('更新预览'),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _result == null
                ? const Text('输入内容后点击“更新预览”')
                : _MarkdownBlocks(blocks: _result!.blocks),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _input.text.isEmpty ? null : _copy,
                child: const Text('复制源码'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _input.text.isEmpty ? null : _confirmClear,
                child: const Text('清空'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('不执行 HTML、脚本或网络资源'),
          ),
        ),
        const SizedBox(height: 8),
        const Text('内容仅保留在当前页面', style: TextStyle(color: AppColors.muted)),
      ],
    ),
  );
}

class _MarkdownBlocks extends StatelessWidget {
  const _MarkdownBlocks({required this.blocks});

  final List<MarkdownBlock> blocks;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('预览结果', style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 12),
      for (final block in blocks) _MarkdownBlockView(block: block),
    ],
  );
}

class _MarkdownBlockView extends StatelessWidget {
  const _MarkdownBlockView({required this.block});

  final MarkdownBlock block;

  @override
  Widget build(BuildContext context) {
    if (block.type == MarkdownBlockType.code) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        color: AppColors.canvas,
        child: SelectableText(block.text),
      );
    }
    final style = switch (block.type) {
      MarkdownBlockType.heading => TextStyle(
        fontSize: switch (block.level) {
          1 => 24,
          2 => 20,
          _ => 17,
        },
        fontWeight: FontWeight.w700,
      ),
      _ => const TextStyle(fontSize: 15),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.type == MarkdownBlockType.bullet)
            const Padding(padding: EdgeInsets.only(right: 8), child: Text('•')),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.merge(style),
                children: [
                  for (final part in parseBoldSegments(block.text))
                    TextSpan(
                      text: part.text,
                      style: part.bold
                          ? const TextStyle(fontWeight: FontWeight.w700)
                          : null,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
