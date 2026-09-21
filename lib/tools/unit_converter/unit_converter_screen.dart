import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'unit_converter_logic.dart';

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
  UnitConversionResult? result;

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  void _invalidate() => setState(() => result = null);

  void _changeKind(String? value) {
    if (value == null) return;
    final pair = defaultUnitPairs[value]!;
    setState(() {
      kind = value;
      from = pair.$1;
      to = pair.$2;
      result = null;
    });
  }

  void _convert() => setState(() {
    result = convertUnit(
      input: inputController.text,
      kind: kind,
      from: from,
      to: to,
    );
  });

  void _swapUnits() => setState(() {
    final old = from;
    from = to;
    to = old;
    result = null;
  });

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '单位换算',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DropdownButtonFormField<String>(
          initialValue: kind,
          decoration: const InputDecoration(labelText: '换算类型'),
          items: conversionUnits.keys
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: _changeKind,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('unitValueInput'),
          controller: inputController,
          maxLength: maxUnitInputLength,
          // 数值文本必须原样进入逻辑层；过滤字符或截断会把无效输入变成另一个数值。
          maxLengthEnforcement: MaxLengthEnforcement.none,
          onChanged: (_) => _invalidate(),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: const InputDecoration(labelText: '数值', counterText: ''),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final fromField = _unitField(
              '从',
              from,
              (value) => setState(() {
                if (value != null) from = value;
                result = null;
              }),
            );
            final toField = _unitField(
              '到',
              to,
              (value) => setState(() {
                if (value != null) to = value;
                result = null;
              }),
            );
            if (constraints.maxWidth < 480) {
              return Column(
                children: [
                  fromField,
                  IconButton(
                    tooltip: '交换单位',
                    onPressed: _swapUnits,
                    icon: const Icon(Icons.swap_vert),
                  ),
                  toField,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: fromField),
                IconButton(
                  tooltip: '交换单位',
                  onPressed: _swapUnits,
                  icon: const Icon(Icons.swap_horiz),
                ),
                Expanded(child: toField),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('convertUnit'),
          onPressed: _convert,
          child: const Text('开始换算'),
        ),
        if (result?.error != null) ...[
          const SizedBox(height: 12),
          Text(result!.error!, style: const TextStyle(color: AppColors.danger)),
        ],
        if (result?.isSuccess ?? false) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Text('换算结果'),
                  const SizedBox(height: 8),
                  SelectableText(
                    '${formatUnitValue(result!.value!)} ${unitSymbol(to)}',
                    key: const Key('unitConversionResult'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (kind == '数据容量') ...[
                    const SizedBox(height: 16),
                    const Text('1 GB = 1,000,000,000 字节'),
                    const SizedBox(height: 4),
                    const Text('1 GiB = 1,073,741,824 字节'),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (kind == '数据容量') ...[
          const SizedBox(height: 12),
          const Text(
            'KB/MB/GB/TB 使用十进制，KiB/MiB/GiB/TiB 使用二进制；不会读取文件。',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ],
    ),
  );

  Widget _unitField(
    String label,
    String value,
    ValueChanged<String?> changed,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: conversionUnits[kind]!
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: changed,
  );
}
