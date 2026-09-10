import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'statistics_calculator_logic.dart';

class StatisticsCalculatorScreen extends StatefulWidget {
  const StatisticsCalculatorScreen({super.key});

  @override
  State<StatisticsCalculatorScreen> createState() =>
      _StatisticsCalculatorScreenState();
}

class _StatisticsCalculatorScreenState
    extends State<StatisticsCalculatorScreen> {
  final _input = TextEditingController(text: '12, 18, 20, 25, 30');
  StatisticsResult? _result;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _calculate() {
    try {
      final result = calculateStatistics(_input.text);
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

  Map<String, String> _resultValues(StatisticsResult result) => {
    '数量': '${result.count}',
    '总和': formatStatisticNumber(result.sum),
    '平均值': formatStatisticNumber(result.mean),
    '中位数': formatStatisticNumber(result.median),
    '最小值': formatStatisticNumber(result.minimum),
    '最大值': formatStatisticNumber(result.maximum),
    '极差': formatStatisticNumber(result.range),
    '总体标准差': formatStatisticNumber(result.populationStandardDeviation),
    '样本标准差': result.sampleStandardDeviation == null
        ? '至少需要 2 个数字'
        : formatStatisticNumber(result.sampleStandardDeviation!),
  };

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '统计计算',
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
                TextField(
                  key: const Key('statisticsInput'),
                  controller: _input,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: maxStatisticsInputLength,
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '数字列表',
                    alignLabelWithHint: true,
                    helperText: '支持英文逗号、空格或换行分隔',
                    errorText: _error,
                    errorMaxLines: 3,
                  ),
                  onChanged: (_) => setState(() {
                    _result = null;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('calculateStatistics'),
                  onPressed: _calculate,
                  child: const Text('计算统计'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_result case final result?) ...[
          const Text(
            '计算结果',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final values = _resultValues(result).entries.toList();
              final cardWidth = constraints.maxWidth < 330
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final entry in values)
                    SizedBox(
                      width: cardWidth,
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(color: AppColors.muted),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          CopyResultButton(
            text: _resultValues(result).entries
                .map((entry) => '${entry.key}: ${entry.value}')
                .join('\n'),
          ),
        ] else
          const Text('输入数字列表后点击“计算统计”'),
        const SizedBox(height: 16),
        const Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.calculate_outlined, color: AppColors.primary),
            title: Text('最多处理 10000 个数字'),
            subtitle: Text('全部数据只在本机内存中计算，不会保存'),
          ),
        ),
      ],
    ),
  );
}
