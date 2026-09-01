import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'percentage_calculator_logic.dart';

class PercentageCalculatorScreen extends StatefulWidget {
  const PercentageCalculatorScreen({super.key});

  @override
  State<PercentageCalculatorScreen> createState() =>
      _PercentageCalculatorScreenState();
}

class _PercentageCalculatorScreenState
    extends State<PercentageCalculatorScreen> {
  final partController = TextEditingController(text: '20');
  final totalController = TextEditingController(text: '80');
  final valueController = TextEditingController(text: '100');
  final changeController = TextEditingController(text: '15');
  final priceController = TextEditingController(text: '299');
  final discountController = TextEditingController(text: '8.5');

  @override
  void dispose() {
    for (final controller in [
      partController,
      totalController,
      valueController,
      changeController,
      priceController,
      discountController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final part = _number(partController);
    final total = _number(totalController);
    final value = _number(valueController);
    final change = _number(changeController);
    final price = _number(priceController);
    final discount = _number(discountController);
    final percentResult = part == null || total == null
        ? null
        : percentageOf(part, total);
    final changeResult = value == null || change == null
        ? null
        : applyPercentageChange(value, change);
    final discountResult = price == null || discount == null
        ? null
        : discountedPrice(price, discount);

    return ToolPageScaffold(
      title: '百分比计算',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _card(
            title: '求百分比',
            fields: [
              _field(partController, '部分'),
              _field(totalController, '总数'),
            ],
            result: percentResult == null
                ? '请输入有效数值，总数不能为 0'
                : '${formatNumber(part!)} 是 ${formatNumber(total!)} 的 ${formatNumber(percentResult)}%',
          ),
          _card(
            title: '百分比增减',
            fields: [
              _field(valueController, '原数值'),
              _field(changeController, '增减百分比', suffix: '%'),
            ],
            result: changeResult == null
                ? '请输入有效百分比'
                : '${formatNumber(value!)} ${change! >= 0 ? '增加' : '减少'} ${formatNumber(change.abs())}% = ${formatNumber(changeResult)}',
          ),
          _card(
            title: '折扣计算',
            fields: [
              _field(priceController, '原价', prefix: '¥'),
              _field(discountController, '折扣', suffix: '折'),
            ],
            result: discountResult == null
                ? '折扣请输入 0～10'
                : '到手价  ¥${discountResult.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? prefix,
    String? suffix,
  }) => TextField(
    controller: controller,
    onChanged: (_) => setState(() {}),
    keyboardType: const TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    ),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))],
    decoration: InputDecoration(
      labelText: label,
      prefixText: prefix,
      suffixText: suffix,
    ),
  );

  Widget _card({
    required String title,
    required List<Widget> fields,
    required String result,
  }) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < 380
                ? Column(
                    children: [
                      for (final field in fields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: field,
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 10),
                      Expanded(child: fields[1]),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            result,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: result.startsWith('请输入') || result.startsWith('折扣')
                  ? AppColors.danger
                  : AppColors.primary,
            ),
          ),
        ],
      ),
    ),
  );
}
