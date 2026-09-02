import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'csv_json_converter_logic.dart';

class CsvJsonConverterScreen extends StatefulWidget {
  const CsvJsonConverterScreen({super.key});

  @override
  State<CsvJsonConverterScreen> createState() => _CsvJsonConverterScreenState();
}

class _CsvJsonConverterScreenState extends State<CsvJsonConverterScreen> {
  final inputController = TextEditingController(
    text: 'name,age\nAlice,30\nBob,25',
  );
  final outputController = TextEditingController();
  CsvJsonMode mode = CsvJsonMode.csvToJson;
  String? error;

  @override
  void dispose() {
    inputController.dispose();
    outputController.dispose();
    super.dispose();
  }

  void _convert() {
    final result = convertCsvJson(inputController.text, mode);
    setState(() {
      error = result.error;
      outputController.text = result.output;
    });
  }

  void _clear() => setState(() {
    inputController.clear();
    outputController.clear();
    error = null;
  });

  Future<void> _copy() async {
    if (outputController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: outputController.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('转换结果已复制')));
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'CSV/JSON 转换',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<CsvJsonMode>(
          segments: const [
            ButtonSegment(
              value: CsvJsonMode.csvToJson,
              label: Text('CSV → JSON'),
            ),
            ButtonSegment(
              value: CsvJsonMode.jsonToCsv,
              label: Text('JSON → CSV'),
            ),
          ],
          selected: {mode},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            mode = selection.first;
            error = null;
            outputController.clear();
            inputController.text = mode == CsvJsonMode.csvToJson
                ? 'name,age\nAlice,30\nBob,25'
                : '[\n  {"name": "Alice", "age": 30},\n  {"name": "Bob", "age": 25}\n]';
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('csvJsonInput'),
          controller: inputController,
          minLines: 7,
          maxLines: 12,
          maxLength: maxCsvJsonInputLength,
          decoration: const InputDecoration(
            labelText: '输入',
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
          key: const Key('csvJsonOutput'),
          controller: outputController,
          readOnly: true,
          minLines: 8,
          maxLines: 14,
          decoration: InputDecoration(
            labelText: '转换结果',
            alignLabelWithHint: true,
            suffixIcon: IconButton(
              tooltip: '复制',
              onPressed: outputController.text.isEmpty ? null : _copy,
              icon: const Icon(Icons.copy_outlined),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _convert, child: const Text('转换')),
        const SizedBox(height: 8),
        TextButton(onPressed: _clear, child: const Text('清空')),
        const Text(
          '仅处理文本；不会执行 CSV 公式或访问文件。将结果粘贴到表格软件前，请留意以 =、+、-、@ 开头的字段。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
