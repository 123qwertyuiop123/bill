import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'text_tools_logic.dart';

enum _TextToolMode { basic, htmlEntities }

class TextToolsScreen extends StatefulWidget {
  const TextToolsScreen({super.key});

  @override
  State<TextToolsScreen> createState() => _TextToolsScreenState();
}

class _TextToolsScreenState extends State<TextToolsScreen> {
  final controller = TextEditingController();
  final outputController = TextEditingController();
  _TextToolMode mode = _TextToolMode.basic;
  HtmlEntityMode entityMode = HtmlEntityMode.encode;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    outputController.dispose();
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

  void _convertEntities() {
    final result = entityMode == HtmlEntityMode.encode
        ? encodeHtmlEntities(controller.text)
        : decodeHtmlEntities(controller.text);
    setState(() {
      error = result.error;
      outputController.text = result.text;
    });
  }

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
    var message = '已复制';
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      message = '复制失败，请重试';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmClear() async {
    if (controller.text.isEmpty && outputController.text.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空内容？'),
        content: const Text('当前输入和转换结果将被清空。'),
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
      controller.clear();
      outputController.clear();
      error = null;
    });
  }

  void _onInputChanged() {
    setState(() {
      error = null;
      outputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '文本工具',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('统计、转换与清理文本'),
        const SizedBox(height: 16),
        DropdownButtonFormField<_TextToolMode>(
          initialValue: mode,
          decoration: const InputDecoration(labelText: '功能'),
          items: const [
            DropdownMenuItem(value: _TextToolMode.basic, child: Text('基础处理')),
            DropdownMenuItem(
              value: _TextToolMode.htmlEntities,
              child: Text('HTML 实体'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              mode = value;
              error = null;
              outputController.clear();
            });
          },
        ),
        const SizedBox(height: 16),
        if (mode == _TextToolMode.htmlEntities)
          ..._buildEntityMode()
        else
          ..._buildBasicMode(),
      ],
    ),
  );

  List<Widget> _buildBasicMode() => [
    TextField(
      key: const Key('textToolsInput'),
      controller: controller,
      onChanged: (_) => _onInputChanged(),
      minLines: 8,
      maxLines: 16,
      maxLength: maxTextToolInputLength,
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
              : () => _copy(controller.text),
          icon: const Icon(Icons.copy_outlined),
          label: const Text('复制'),
        ),
        TextButton(
          onPressed: controller.text.isEmpty ? null : _confirmClear,
          child: const Text('清空'),
        ),
      ],
    ),
  ];

  List<Widget> _buildEntityMode() => [
    SegmentedButton<HtmlEntityMode>(
      segments: const [
        ButtonSegment(value: HtmlEntityMode.encode, label: Text('编码')),
        ButtonSegment(value: HtmlEntityMode.decode, label: Text('解码')),
      ],
      selected: {entityMode},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => setState(() {
        entityMode = selection.first;
        error = null;
        outputController.clear();
      }),
    ),
    const SizedBox(height: 16),
    TextField(
      key: const Key('htmlEntityInput'),
      controller: controller,
      onChanged: (_) => _onInputChanged(),
      minLines: 5,
      maxLines: 10,
      maxLength: maxTextToolInputLength,
      maxLengthEnforcement: MaxLengthEnforcement.none,
      decoration: InputDecoration(
        labelText: '输入文本',
        alignLabelWithHint: true,
        errorText: error,
      ),
    ),
    FilledButton(
      key: const Key('convertHtmlEntities'),
      onPressed: _convertEntities,
      child: Text(entityMode == HtmlEntityMode.encode ? '开始编码' : '开始解码'),
    ),
    const SizedBox(height: 16),
    TextField(
      key: const Key('htmlEntityOutput'),
      controller: outputController,
      readOnly: true,
      minLines: 4,
      maxLines: 10,
      decoration: const InputDecoration(
        labelText: '转换结果',
        alignLabelWithHint: true,
      ),
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: outputController.text.isEmpty
                ? null
                : () => _copy(outputController.text),
            child: const Text('复制结果'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: controller.text.isEmpty && outputController.text.isEmpty
                ? null
                : _confirmClear,
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
        child: Text('只转换字符，不渲染或执行 HTML'),
      ),
    ),
    const SizedBox(height: 8),
    const Text('内容仅在本机内存中处理', style: TextStyle(color: AppColors.muted)),
  ];
}
