import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'roman_numeral_converter_logic.dart';

class RomanNumeralConverterScreen extends StatefulWidget {
  const RomanNumeralConverterScreen({super.key});

  @override
  State<RomanNumeralConverterScreen> createState() =>
      _RomanNumeralConverterScreenState();
}

class _RomanNumeralConverterScreenState
    extends State<RomanNumeralConverterScreen> {
  final _input = TextEditingController(text: '2026');
  RomanConversionMode _mode = RomanConversionMode.numberToRoman;
  RomanConversionResult? _result;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _invalidate() => setState(() {
    _result = null;
    _error = null;
  });

  void _convert() {
    try {
      final result = convertRoman(_input.text, _mode);
      setState(() {
        _result = result;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '罗马数字',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<RomanConversionMode>(
                  segments: const [
                    ButtonSegment(
                      value: RomanConversionMode.numberToRoman,
                      label: Text('数字转罗马'),
                    ),
                    ButtonSegment(
                      value: RomanConversionMode.romanToNumber,
                      label: Text('罗马转数字'),
                    ),
                  ],
                  selected: {_mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => setState(() {
                    _mode = selection.first;
                    // 切换方向只使旧结果失效，保留用户尚未处理的输入。
                    _result = null;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('romanInput'),
                  controller: _input,
                  maxLength: maxRomanInputLength,
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: _mode == RomanConversionMode.romanToNumber
                      ? TextCapitalization.characters
                      : TextCapitalization.none,
                  keyboardType: _mode == RomanConversionMode.numberToRoman
                      ? TextInputType.number
                      : TextInputType.text,
                  inputFormatters: _mode == RomanConversionMode.numberToRoman
                      ? [FilteringTextInputFormatter.digitsOnly]
                      : [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[IVXLCDMivxlcdm]'),
                          ),
                        ],
                  decoration: InputDecoration(
                    labelText: _mode == RomanConversionMode.numberToRoman
                        ? '十进制整数'
                        : '罗马数字',
                    helperText: _mode == RomanConversionMode.numberToRoman
                        ? '范围 1–3999'
                        : '例如 MMXXVI，支持小写输入',
                    errorText: _error,
                    errorMaxLines: 3,
                  ),
                  onChanged: (_) => _invalidate(),
                  onSubmitted: (_) => _convert(),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('convertRoman'),
                  onPressed: _convert,
                  child: const Text('转换'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_result case final result?)
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '转换结果',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    result.output,
                    key: const Key('romanResult'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(result.explanation),
                  const SizedBox(height: 12),
                  CopyResultButton(text: result.output),
                ],
              ),
            ),
          )
        else
          const Text('输入内容后点击“转换”'),
        const SizedBox(height: 16),
        const Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.primary),
            title: Text('仅支持规范形式'),
            subtitle: Text('不会保存输入或结果，也不支持 0、负数和小数'),
          ),
        ),
      ],
    ),
  );
}
