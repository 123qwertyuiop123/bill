import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'bill_split_logic.dart';

class BillSplitScreen extends StatefulWidget {
  const BillSplitScreen({super.key});

  @override
  State<BillSplitScreen> createState() => _BillSplitScreenState();
}

class _BillSplitScreenState extends State<BillSplitScreen> {
  final totalController = TextEditingController(text: '368');
  final peopleController = TextEditingController(text: '4');
  final feeController = TextEditingController(text: '0');

  @override
  void dispose() {
    totalController.dispose();
    peopleController.dispose();
    feeController.dispose();
    super.dispose();
  }

  double? get result {
    final total = double.tryParse(totalController.text);
    final people = int.tryParse(peopleController.text);
    final fee = double.tryParse(feeController.text);
    if (total == null || people == null || fee == null) return null;
    return splitBill(total: total, people: people, extraFee: fee);
  }

  Future<void> _copy() async {
    final value = result;
    if (value == null) return;
    await Clipboard.setData(
      ClipboardData(text: '每人应付 ¥${value.toStringAsFixed(2)}'),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('分摊结果已复制')));
    }
  }

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: 'AA 分摊',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _field(totalController, '总金额', prefix: '¥', decimal: true),
        const SizedBox(height: 12),
        _field(peopleController, '人数', decimal: false),
        const SizedBox(height: 12),
        _field(feeController, '服务费（可选）', prefix: '¥', decimal: true),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: AppColors.selected,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('每人应付'),
                const SizedBox(height: 8),
                Text(
                  result == null ? '—' : '¥${result!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: result == null ? null : _copy,
          icon: const Icon(Icons.copy_outlined),
          label: const Text('复制结果'),
        ),
        if (result == null)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              '金额不能为负数，人数应为 1～10000。',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? prefix,
    required bool decimal,
  }) => TextField(
    controller: controller,
    onChanged: (_) => setState(() {}),
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
      ),
    ],
    decoration: InputDecoration(labelText: label, prefixText: prefix),
  );
}
