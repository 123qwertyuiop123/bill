import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'matrix_calculator_logic.dart';

/// 控制器只保存当前页面输入，切换阶数不丢弃已输入的单元格。
class MatrixCalculatorScreen extends StatefulWidget {
  const MatrixCalculatorScreen({super.key});
  @override
  State<MatrixCalculatorScreen> createState() => _MatrixCalculatorScreenState();
}

class _MatrixCalculatorScreenState extends State<MatrixCalculatorScreen> {
  final _inputs = List.generate(
    3,
    (i) => List.generate(
      3,
      (j) => TextEditingController(
        text: i < 2 && j < 2 ? '${i * 2 + j + 1}' : (i == j ? '1' : '0'),
      ),
    ),
  );
  int _size = 2;
  MatrixOperation _operation = MatrixOperation.determinant;
  MatrixResult? _result;
  String? _error;
  @override
  void dispose() {
    for (final row in _inputs) {
      for (final input in row) {
        input.dispose();
      }
    }
    super.dispose();
  }

  void _invalidate() {
    _result = null;
    _error = null;
  }

  void _calculate() => setState(() {
    _invalidate();
    try {
      _result = calculateMatrix(
        List.generate(
          _size,
          (i) => List.generate(_size, (j) => _inputs[i][j].text),
        ),
        _operation,
      );
    } on FormatException catch (error) {
      _error = error.message;
    }
  });
  Widget _field(int row, int column) => TextField(
    key: ValueKey('matrix-$row-$column'),
    controller: _inputs[row][column],
    maxLength: 32,
    maxLengthEnforcement: MaxLengthEnforcement.none,
    keyboardType: const TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    ),
    autocorrect: false,
    enableSuggestions: false,
    decoration: InputDecoration(
      labelText: '第${row + 1}行${column + 1}列',
      counterText: '',
    ),
    onChanged: (_) => setState(_invalidate),
  );
  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '矩阵计算',
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
                DropdownButtonFormField<int>(
                  initialValue: _size,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '矩阵阶数'),
                  items: [2, 3]
                      .map(
                        (n) => DropdownMenuItem(value: n, child: Text('$n×$n')),
                      )
                      .toList(),
                  onChanged: (n) {
                    if (n != null) {
                      setState(() {
                        _size = n;
                        _invalidate();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MatrixOperation>(
                  initialValue: _operation,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '计算类型'),
                  items: MatrixOperation.values
                      .map(
                        (op) =>
                            DropdownMenuItem(value: op, child: Text(op.label)),
                      )
                      .toList(),
                  onChanged: (op) {
                    if (op != null) {
                      setState(() {
                        _operation = op;
                        _invalidate();
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                // 放大字体或窄屏时按列逐项输入，避免强行塞入固定三列而溢出。
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxWidth / _size <
                        120 * MediaQuery.textScalerOf(context).scale(1);
                    return Column(
                      children: [
                        for (var i = 0; i < _size; i++) ...[
                          if (compact)
                            for (var j = 0; j < _size; j++) ...[
                              _field(i, j),
                              const SizedBox(height: 12),
                            ]
                          else
                            Row(
                              children: [
                                for (var j = 0; j < _size; j++) ...[
                                  if (j > 0) const SizedBox(width: 8),
                                  Expanded(child: _field(i, j)),
                                ],
                              ],
                            ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                FilledButton(
                  key: const Key('calculateMatrix'),
                  onPressed: _calculate,
                  child: const Text('开始计算'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_result case final result?) ...[
          ToolResultCard(
            values: {
              '计算类型': _operation.label,
              if (result.determinant != null)
                '结果': formatMatrixNumber(result.determinant!),
              if (result.matrix != null)
                for (var i = 0; i < _size; i++)
                  '第${i + 1}行': result.matrix![i]
                      .map(formatMatrixNumber)
                      .join('  '),
            },
          ),
          const SizedBox(height: 12),
          CopyResultButton(
            text: result.determinant != null
                ? formatMatrixNumber(result.determinant!)
                : result.matrix!
                      .map((row) => row.map(formatMatrixNumber).join(','))
                      .join('\n'),
          ),
        ] else
          const Text('输入矩阵后点击“开始计算”'),
        const SizedBox(height: 16),
        const Text('仅支持 2/3 阶行列式、转置和逆矩阵；结果为近似值，接近奇异时拒绝求逆。不保存输入'),
      ],
    ),
  );
}
