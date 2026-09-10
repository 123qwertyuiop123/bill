import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'unicode_inspector_logic.dart';

class UnicodeInspectorScreen extends StatefulWidget {
  const UnicodeInspectorScreen({super.key});

  @override
  State<UnicodeInspectorScreen> createState() => _UnicodeInspectorScreenState();
}

class _UnicodeInspectorScreenState extends State<UnicodeInspectorScreen> {
  final _input = TextEditingController(text: '中A😊');
  UnicodeFilter _filter = UnicodeFilter.all;
  UnicodeInspectionResult _result = const UnicodeInspectionResult();

  @override
  void initState() {
    super.initState();
    _inspect();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _inspect() => setState(() {
    _result = inspectUnicode(_input.text, filter: _filter);
  });

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'Unicode 检查',
    child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          sliver: SliverList.list(
            children: [
              TextField(
                key: const Key('unicodeInput'),
                controller: _input,
                maxLength: maxUnicodeInputCharacters,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                decoration: InputDecoration(
                  labelText: '输入字符',
                  errorText: _result.error,
                  errorMaxLines: 2,
                ),
                onChanged: (_) => _inspect(),
              ),
              const SizedBox(height: 8),
              SegmentedButton<UnicodeFilter>(
                segments: const [
                  ButtonSegment(value: UnicodeFilter.all, label: Text('全部字符')),
                  ButtonSegment(
                    value: UnicodeFilter.asciiOnly,
                    label: Text('仅 ASCII'),
                  ),
                ],
                selected: {_filter},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  _filter = selection.first;
                  _inspect();
                },
              ),
              const SizedBox(height: 12),
              if (_result.isSuccess && _result.entries.isEmpty)
                const Text('当前筛选条件下没有字符'),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: _result.entries.length,
            itemBuilder: (context, index) {
              final entry = _result.entries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.displayCharacter,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SelectableText(entry.codePoint),
                        ],
                      ),
                      const Divider(),
                      SelectableText('UTF-8　${entry.utf8Hex}'),
                      const SizedBox(height: 4),
                      SelectableText('UTF-16　${entry.utf16Hex}'),
                      const SizedBox(height: 4),
                      SelectableText('Dart　${entry.dartEscape}'),
                      const SizedBox(height: 4),
                      SelectableText('JSON　${entry.jsonEscape}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          sliver: SliverList.list(
            children: [
              CopyResultButton(text: _result.copyText),
              const SizedBox(height: 12),
              const Text(
                '最多 256 个字符 · 不进行字体检测或语言识别',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
