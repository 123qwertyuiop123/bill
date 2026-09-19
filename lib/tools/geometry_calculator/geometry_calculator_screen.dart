import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import 'geometry_calculator_logic.dart';

/// 几何量计算页面；每个形状的输入和公式保持一致。
class GeometryCalculatorScreen extends StatefulWidget {
  const GeometryCalculatorScreen({super.key});
  @override
  State<GeometryCalculatorScreen> createState() =>
      _GeometryCalculatorScreenState();
}

class _GeometryCalculatorScreenState extends State<GeometryCalculatorScreen> {
  final _inputs = [
    TextEditingController(text: '12'),
    TextEditingController(text: '8'),
    TextEditingController(text: '10'),
  ];
  GeometryShape _shape = GeometryShape.rectangle;
  GeometryResult? _result;
  String? _error;
  @override
  void dispose() {
    for (final input in _inputs) {
      input.dispose();
    }
    super.dispose();
  }

  void _calculate() => setState(() {
    _error = null;
    _result = null;
    try {
      _result = calculateGeometry(
        _shape,
        _inputs.take(_shape.fields.length).map((c) => c.text).toList(),
      );
    } on FormatException catch (error) {
      _error = error.message;
    }
  });
  Map<String, String> _values(GeometryResult result) => {
    '面积': '${formatGeometryNumber(result.area)} 单位²',
    '周长': '${formatGeometryNumber(result.perimeter)} 单位',
    '面积公式': _shape.areaFormula,
    '周长公式': _shape.perimeterFormula,
  };

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '几何计算',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<GeometryShape>(
          segments: [
            for (final shape in GeometryShape.values)
              ButtonSegment(value: shape, label: Text(shape.label)),
          ],
          selected: {_shape},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => setState(() {
            _shape = selection.first;
            // 切换形状使结果失效，但不清除用户尚未计算的长度。
            _result = null;
            _error = null;
          }),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _shape.fields.length; i++) ...[
                  TextField(
                    key: ValueKey('geometryLength-$i'),
                    controller: _inputs[i],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    maxLength: maxGeometryInputLength,
                    maxLengthEnforcement: MaxLengthEnforcement.none,
                    decoration: InputDecoration(
                      labelText: _shape.fields[i],
                      errorText: i == 0 ? _error : null,
                      errorMaxLines: 3,
                    ),
                    onChanged: (_) => setState(() {
                      _result = null;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text('所有长度使用相同单位'),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('calculateGeometry'),
                  onPressed: _calculate,
                  child: const Text('开始计算'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_result case final result?) ...[
          ToolResultCard(values: _values(result)),
          const SizedBox(height: 12),
          CopyResultButton(
            text: _values(result).entries
                .map((e) => '${e.key}: ${e.value}')
                .join('\n'),
          ),
        ] else
          const Text('选择形状并输入所需长度'),
        const SizedBox(height: 16),
        const Text('只做数值计算，不测量图片；结果为近似值，输入不会保存'),
      ],
    ),
  );
}
