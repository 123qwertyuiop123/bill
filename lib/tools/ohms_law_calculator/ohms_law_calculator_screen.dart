import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'ohms_law_calculator_logic.dart';

class OhmsLawCalculatorScreen extends StatefulWidget {
  const OhmsLawCalculatorScreen({super.key});

  @override
  State<OhmsLawCalculatorScreen> createState() =>
      _OhmsLawCalculatorScreenState();
}

class _OhmsLawCalculatorScreenState extends State<OhmsLawCalculatorScreen> {
  final _firstValue = TextEditingController(text: '12');
  final _secondValue = TextEditingController(text: '100');
  OhmsKnownPair _pair = OhmsKnownPair.voltageResistance;
  late ElectricalUnit _firstUnit;
  late ElectricalUnit _secondUnit;
  OhmsLawResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resetUnits();
  }

  @override
  void dispose() {
    _firstValue.dispose();
    _secondValue.dispose();
    super.dispose();
  }

  void _resetUnits() {
    final (first, second) = _pair.quantities;
    _firstUnit = baseUnitFor(first);
    _secondUnit = baseUnitFor(second);
  }

  void _clearResult() => setState(() {
    _result = null;
    _error = null;
  });

  void _calculate() {
    final first = double.tryParse(_firstValue.text.trim());
    final second = double.tryParse(_secondValue.text.trim());
    if (first == null || second == null) {
      setState(() {
        _result = null;
        _error = '请输入有效数值';
      });
      return;
    }
    try {
      final result = calculateOhmsLaw(
        pair: _pair,
        firstValue: first * _firstUnit.factor,
        secondValue: second * _secondUnit.factor,
      );
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
  Widget build(BuildContext context) {
    final (firstQuantity, secondQuantity) = _pair.quantities;
    return ToolPageScaffold(
      title: '欧姆定律',
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
                  const Text(
                    '选择两个已知量',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<OhmsKnownPair>(
                    key: const Key('ohmsPair'),
                    initialValue: _pair,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: '已知量组合'),
                    items: [
                      for (final pair in OhmsKnownPair.values)
                        DropdownMenuItem(value: pair, child: Text(pair.label)),
                    ],
                    onChanged: (pair) {
                      if (pair == null) return;
                      setState(() {
                        _pair = pair;
                        _resetUnits();
                        _firstValue.clear();
                        _secondValue.clear();
                        _result = null;
                        _error = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth < 430
                        ? Column(
                            children: [
                              _quantityInput(
                                controller: _firstValue,
                                quantity: firstQuantity,
                                unit: _firstUnit,
                                onUnitChanged: (unit) {
                                  _firstUnit = unit;
                                  _clearResult();
                                },
                              ),
                              const SizedBox(height: 12),
                              _quantityInput(
                                controller: _secondValue,
                                quantity: secondQuantity,
                                unit: _secondUnit,
                                onUnitChanged: (unit) {
                                  _secondUnit = unit;
                                  _clearResult();
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _quantityInput(
                                  controller: _firstValue,
                                  quantity: firstQuantity,
                                  unit: _firstUnit,
                                  onUnitChanged: (unit) {
                                    _firstUnit = unit;
                                    _clearResult();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _quantityInput(
                                  controller: _secondValue,
                                  quantity: secondQuantity,
                                  unit: _secondUnit,
                                  onUnitChanged: (unit) {
                                    _secondUnit = unit;
                                    _clearResult();
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      key: const Key('ohmsError'),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('calculateOhmsLaw'),
                    onPressed: _calculate,
                    child: const Text('开始计算'),
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
            ToolResultCard(
              values: {
                for (final quantity in ElectricalQuantity.values)
                  quantity.label: formatElectricalValue(
                    quantity,
                    result.valueOf(quantity),
                  ),
                '关系式': _pair.formula,
              },
            ),
            const SizedBox(height: 12),
            CopyResultButton(
              text: ElectricalQuantity.values
                  .map(
                    (quantity) =>
                        '${quantity.label}: ${formatElectricalValue(quantity, result.valueOf(quantity))}',
                  )
                  .followedBy(['关系式: ${_pair.formula}'])
                  .join('\n'),
            ),
          ] else
            const Text('选择组合并输入两个已知量'),
          const SizedBox(height: 16),
          const Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.primary),
              title: Text('输入必须大于 0'),
              subtitle: Text('结果仅用于一般计算，请按实际测量误差判断'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityInput({
    required TextEditingController controller,
    required ElectricalQuantity quantity,
    required ElectricalUnit unit,
    required ValueChanged<ElectricalUnit> onUnitChanged,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final valueField = TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.eE+-]')),
        ],
        maxLength: 24,
        maxLengthEnforcement: MaxLengthEnforcement.none,
        decoration: InputDecoration(labelText: quantity.label, counterText: ''),
        onChanged: (_) => _clearResult(),
      );
      final unitField = DropdownButtonFormField<ElectricalUnit>(
        initialValue: unit,
        isExpanded: true,
        decoration: const InputDecoration(labelText: '单位'),
        items: [
          for (final item in unitsFor(quantity))
            DropdownMenuItem(value: item, child: Text(item.label)),
        ],
        onChanged: (selected) {
          if (selected != null) onUnitChanged(selected);
        },
      );
      // 大字体下给单位下拉框完整宽度，避免文字和箭头互相挤压。
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
      if (largeText || constraints.maxWidth < 240) {
        return Column(
          children: [valueField, const SizedBox(height: 8), unitField],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: valueField),
          const SizedBox(width: 8),
          SizedBox(width: 92, child: unitField),
        ],
      );
    },
  );
}
