import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final inputController = TextEditingController(text: '1');
  String kind = '长度';
  String from = '米';
  String to = '千米';

  static const units = <String, List<String>>{
    '长度': ['毫米', '厘米', '米', '千米'],
    '重量': ['克', '千克', '吨'],
    '温度': ['摄氏度', '华氏度', '开尔文'],
  };

  static const factors = <String, double>{
    '毫米': .001,
    '厘米': .01,
    '米': 1,
    '千米': 1000,
    '克': .001,
    '千克': 1,
    '吨': 1000,
  };

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  double? get result {
    final value = double.tryParse(inputController.text);
    if (value == null) return null;
    if (kind != '温度') return value * factors[from]! / factors[to]!;
    final celsius = switch (from) {
      '华氏度' => (value - 32) * 5 / 9,
      '开尔文' => value - 273.15,
      _ => value,
    };
    return switch (to) {
      '华氏度' => celsius * 9 / 5 + 32,
      '开尔文' => celsius + 273.15,
      _ => celsius,
    };
  }

  void _changeKind(String? value) {
    if (value == null) return;
    setState(() {
      kind = value;
      from = units[value]!.first;
      to = units[value]![1];
    });
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '单位换算',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DropdownButtonFormField<String>(
          initialValue: kind,
          decoration: const InputDecoration(labelText: '换算类型'),
          items: units.keys
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: _changeKind,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: inputController,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
          ],
          decoration: const InputDecoration(labelText: '数值'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _unitField(
                '从',
                from,
                (value) => setState(() => from = value!),
              ),
            ),
            IconButton(
              tooltip: '交换单位',
              onPressed: () => setState(() {
                final old = from;
                from = to;
                to = old;
              }),
              icon: const Icon(Icons.swap_horiz),
            ),
            Expanded(
              child: _unitField(
                '到',
                to,
                (value) => setState(() => to = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Text('换算结果'),
                const SizedBox(height: 8),
                SelectableText(
                  result == null ? '—' : '${_format(result!)} $to',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _unitField(
    String label,
    String value,
    ValueChanged<String?> changed,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: units[kind]!
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: changed,
  );

  String _format(double value) =>
      value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
}
