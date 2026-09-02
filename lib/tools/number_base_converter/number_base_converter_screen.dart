import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'number_base_converter_logic.dart';

class NumberBaseConverterScreen extends StatefulWidget {
  const NumberBaseConverterScreen({super.key});

  @override
  State<NumberBaseConverterScreen> createState() =>
      _NumberBaseConverterScreenState();
}

class _NumberBaseConverterScreenState extends State<NumberBaseConverterScreen> {
  final inputController = TextEditingController(text: '255');
  final outputControllers = <int, TextEditingController>{
    for (final radix in supportedRadices) radix: TextEditingController(),
  };
  int sourceRadix = 10;
  String? error;

  @override
  void dispose() {
    inputController.dispose();
    for (final controller in outputControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _convert() {
    final result = convertNumberBase(inputController.text, sourceRadix);
    setState(() {
      error = result.error;
      for (final radix in supportedRadices) {
        outputControllers[radix]!.text = result.values[radix] ?? '';
      }
    });
  }

  Future<void> _copy(int radix) async {
    final value = outputControllers[radix]!.text;
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('结果已复制')));
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '进制转换',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('源进制', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 2, label: Text('二进制')),
            ButtonSegment(value: 8, label: Text('八进制')),
            ButtonSegment(value: 10, label: Text('十进制')),
            ButtonSegment(value: 16, label: Text('十六进制')),
          ],
          selected: {sourceRadix},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            sourceRadix = selection.first;
            error = null;
            for (final controller in outputControllers.values) {
              controller.clear();
            }
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('numberBaseInput'),
          controller: inputController,
          maxLength: maxNumberBaseInputLength,
          decoration: const InputDecoration(
            labelText: '输入数值',
            helperText: '支持负数；二、八、十六进制可带 0b、0o、0x 前缀',
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
        FilledButton(onPressed: _convert, child: const Text('转换')),
        const SizedBox(height: 20),
        for (final radix in supportedRadices) ...[
          TextField(
            key: Key('numberBaseOutput$radix'),
            controller: outputControllers[radix],
            readOnly: true,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: _radixLabel(radix),
              suffixIcon: IconButton(
                tooltip: '复制',
                onPressed: outputControllers[radix]!.text.isEmpty
                    ? null
                    : () => _copy(radix),
                icon: const Icon(Icons.copy_outlined),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const Text(
          '转换使用任意精度整数，不执行输入内容。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}

String _radixLabel(int radix) => switch (radix) {
  2 => '二进制',
  8 => '八进制',
  10 => '十进制',
  16 => '十六进制',
  _ => '$radix 进制',
};
