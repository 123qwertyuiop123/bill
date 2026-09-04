import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../app/widgets/tool_result_widgets.dart';
import '../../core/app_theme.dart';
import 'luhn_checker_logic.dart';

class LuhnCheckerScreen extends StatefulWidget {
  const LuhnCheckerScreen({super.key});
  @override
  State<LuhnCheckerScreen> createState() => _LuhnCheckerScreenState();
}

class _LuhnCheckerScreenState extends State<LuhnCheckerScreen> {
  final _input = TextEditingController();
  var _mode = LuhnMode.validate;
  LuhnResult? _result;
  String? _error;

  void _process() => setState(() {
    _result = null;
    _error = null;
    try {
      _result = processLuhn(_input.text, _mode);
    } on FormatException catch (e) {
      _error = e.message;
    }
  });

  Map<String, String> _values(LuhnResult result) => {
    '结果': _mode == LuhnMode.generate
        ? '校验位已生成'
        : result.valid
        ? '校验通过'
        : '校验未通过',
    if (_mode == LuhnMode.validate)
      '说明': result.valid ? '符合 Luhn 校验规则' : '不符合 Luhn 校验规则',
    _mode == LuhnMode.generate
        ? '生成的校验数字'
        : '末位校验数字': _mode == LuhnMode.generate
        ? result.digit
        : result.sequence[result.sequence.length - 1],
    if (_mode == LuhnMode.generate) '完整数字序列': result.sequence,
  };

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'Luhn 校验',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('检查数字序列的校验位'),
        const SizedBox(height: 16),
        SegmentedButton<LuhnMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: LuhnMode.validate, label: Text('校验号码')),
            ButtonSegment(value: LuhnMode.generate, label: Text('生成校验位')),
          ],
          selected: {_mode},
          onSelectionChanged: (values) => setState(() {
            _mode = values.first;
            _result = null;
            _error = null;
            // 切换输入语义时清空，避免把含校验位的号码当作待追加校验位的正文。
            _input.clear();
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _input,
          keyboardType: TextInputType.number,
          maxLength: _mode == LuhnMode.validate ? 128 : 127,
          // 校验必须针对完整序列，不能将长号码截断后报告通过。
          maxLengthEnforcement: MaxLengthEnforcement.none,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: _mode == LuhnMode.validate
                ? '数字序列（含校验位）'
                : '数字序列（不含校验位）',
            errorText: _error,
            errorMaxLines: 3,
          ),
          onChanged: (_) => setState(() {
            _result = null;
            _error = null;
          }),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('luhnAction'),
          onPressed: _process,
          child: Text(_mode == LuhnMode.validate ? '开始校验' : '生成校验位'),
        ),
        const SizedBox(height: 16),
        if (_result case final result?)
          ToolResultCard(values: _values(result))
        else
          const Text('输入数字后点击按钮查看结果'),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '校验通过不代表号码真实、存在或可用',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        ),
        const SizedBox(height: 12),
        CopyResultButton(
          text: _result == null
              ? ''
              : '${_values(_result!).entries.map((e) => '${e.key}: ${e.value}').join('\n')}\n校验通过不代表号码真实、存在或可用',
        ),
        const SizedBox(height: 12),
        const Text('仅本地计算，不保存号码'),
      ],
    ),
  );
}
