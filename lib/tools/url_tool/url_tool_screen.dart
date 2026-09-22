import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'url_tool_logic.dart';

const _initialUrlInput = 'https://example.com/search?q=工具箱&page=1&page=2';

class UrlToolScreen extends StatefulWidget {
  const UrlToolScreen({super.key});

  @override
  State<UrlToolScreen> createState() => _UrlToolScreenState();
}

class _UrlToolScreenState extends State<UrlToolScreen> {
  final inputController = TextEditingController(text: _initialUrlInput);
  final outputController = TextEditingController();
  UrlToolMode mode = UrlToolMode.query;
  DomainConversionDirection domainDirection =
      DomainConversionDirection.unicodeToAscii;
  String standardModeInput = _initialUrlInput;
  String domainModeInput = '工具箱.example';
  String? error;

  @override
  void dispose() {
    inputController.dispose();
    outputController.dispose();
    super.dispose();
  }

  void _process() {
    final result = processUrlText(
      inputController.text,
      mode,
      domainDirection: domainDirection,
    );
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<UrlToolMode>(
            segments: const [
              ButtonSegment(value: UrlToolMode.encode, label: Text('编码')),
              ButtonSegment(value: UrlToolMode.decode, label: Text('解码')),
              ButtonSegment(value: UrlToolMode.query, label: Text('参数解析')),
              ButtonSegment(value: UrlToolMode.domain, label: Text('国际域名')),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => setState(() {
              final nextMode = selection.first;
              if (nextMode == UrlToolMode.domain && mode != nextMode) {
                standardModeInput = inputController.text;
                inputController.text = domainModeInput;
              } else if (mode == UrlToolMode.domain && nextMode != mode) {
                domainModeInput = inputController.text;
                inputController.text = standardModeInput;
              }
              mode = nextMode;
              error = null;
              outputController.clear();
            }),
          ),
        ),
        const SizedBox(height: 16),
        if (mode == UrlToolMode.domain) ...[
          SegmentedButton<DomainConversionDirection>(
            segments: const [
              ButtonSegment(
                value: DomainConversionDirection.unicodeToAscii,
                label: Text('Unicode → ASCII'),
              ),
              ButtonSegment(
                value: DomainConversionDirection.asciiToUnicode,
                label: Text('ASCII → Unicode'),
              ),
            ],
            selected: {domainDirection},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => setState(() {
              domainDirection = selection.first;
              error = null;
              outputController.clear();
            }),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          key: const Key('urlInput'),
          controller: inputController,
          minLines: 5,
          maxLines: 9,
          maxLength: mode == UrlToolMode.domain
              ? maxDomainInputLength
              : maxUrlToolInputLength,
          // 超长粘贴由业务规则明确拒绝，不能静默截断成另一个域名。
          maxLengthEnforcement: MaxLengthEnforcement.none,
          decoration: InputDecoration(
            labelText: switch (mode) {
              UrlToolMode.query => 'URL 或查询参数',
              UrlToolMode.domain => '域名',
              _ => '输入',
            },
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
            labelText: switch (mode) {
              UrlToolMode.query => '参数结果',
              UrlToolMode.domain => '转换结果',
              _ => '输出',
            },
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('processUrl'),
          onPressed: _process,
          child: Text(mode == UrlToolMode.domain ? '转换域名' : '处理'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: outputController.text.isEmpty ? null : _copy,
          icon: const Icon(Icons.copy_outlined),
          label: const Text('复制结果'),
        ),
        const SizedBox(height: 8),
        Text(
          mode == UrlToolMode.domain
              ? '仅执行 Punycode 文本转换，不会检查域名是否可注册，也不会打开或请求域名。'
              : '只在本机处理文本，不会打开或请求输入的网址。',
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
