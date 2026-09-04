import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';

class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  State<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen> {
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  double? bmi;

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final height = double.tryParse(heightController.text);
    final weight = double.tryParse(weightController.text);
    setState(() {
      bmi =
          height != null &&
              weight != null &&
              height > 0 &&
              height <= 300 &&
              weight > 0 &&
              weight <= 1000
          ? weight / ((height / 100) * (height / 100))
          : null;
    });
    if (bmi == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入有效的身高和体重')));
    }
  }

  String get _level {
    final value = bmi ?? 0;
    if (value < 18.5) return '偏轻';
    if (value < 24) return '正常';
    if (value < 28) return '偏重';
    return '肥胖';
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'BMI 计算',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: heightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(labelText: '身高', suffixText: '厘米'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(labelText: '体重', suffixText: '千克'),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: _calculate, child: const Text('计算 BMI')),
        if (bmi != null) ...[
          const SizedBox(height: 28),
          Card(
            elevation: 0,
            color: AppColors.selected,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    bmi!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    _level,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          '结果仅供日常参考，不能替代专业医疗建议。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
