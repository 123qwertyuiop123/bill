import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../models/expense_record.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';

/// 新增与编辑共用同一表单，保证收支两种模式使用完全一致的安全校验。
class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({super.key, this.existing, this.initialDate});
  final ExpenseRecord? existing;
  final DateTime? initialDate;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reason;
  late final TextEditingController _amount;
  late DateTime _date;
  late TransactionType _type;
  late TransactionCategory _category;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _reason = TextEditingController(text: item?.reason ?? '');
    _amount = TextEditingController(
      text: item == null ? '' : _displayAmount(item.amount),
    );
    _date = item?.date ?? widget.initialDate ?? DateTime.now();
    _type = item?.type ?? TransactionType.expense;
    _category = item?.category ?? TransactionCategory.food;
  }

  @override
  void dispose() {
    _reason.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '选择日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (result != null && mounted) setState(() => _date = result);
  }

  void _changeType(TransactionType type) {
    setState(() {
      _type = type;
      _category = TransactionCategory.forType(type).first;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final parsed = double.tryParse(_amount.text.trim());
    if (parsed == null) return;
    final existing = widget.existing;
    Navigator.pop(
      context,
      ExpenseRecord(
        // ID 由应用生成且编辑时保持不变，不接受用户输入。
        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        reason: _reason.text.trim(),
        amount: parsed,
        date: DateTime(_date.year, _date.month, _date.day),
        type: _type,
        category: _category,
        ledgerFileId: existing?.ledgerFileId ?? 'default',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      20,
      10,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.existing == null ? '记一笔' : '编辑记录',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('支出'),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('收入'),
                  ),
                ],
                selected: {_type},
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.selected,
                  selectedForegroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                // 编辑时锁定收支方向，避免类型切换导致分类和历史统计歧义。
                onSelectionChanged: widget.existing == null
                    ? (selection) => _changeType(selection.first)
                    : null,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              key: const Key('reasonField'),
              controller: _reason,
              autofocus: true,
              maxLength: 40,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
              decoration: InputDecoration(
                labelText: _type == TransactionType.income ? '收入来源' : '消费原因',
                hintText: _type == TransactionType.income ? '例如：工资' : '例如：午饭',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return _type == TransactionType.income
                      ? '请输入收入来源'
                      : '请输入消费原因';
                }
                if (text.contains(RegExp(r'[\r\n]'))) return '原因不能包含换行';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('amountField'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(12),
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,9}(\.\d{0,2})?'),
                ),
              ],
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
              ),
              validator: (value) {
                final number = double.tryParse(value?.trim() ?? '');
                if (number == null || !number.isFinite || number <= 0) {
                  return '请输入正确的金额';
                }
                if (number > 100000000) return '单笔金额不能超过一亿元';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              _type == TransactionType.income ? '收入种类' : '支出种类',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TransactionCategory.forType(_type)
                  .map((category) {
                    final selected = category == _category;
                    return ChoiceChip(
                      // 按设计要求，分类组件仅显示文字，不显示种类图标。
                      label: Text(category.label),
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: AppColors.selected,
                      side: BorderSide(
                        color: selected ? AppColors.primary : AppColors.line,
                      ),
                      onSelected: (_) => setState(() => _category = category),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined, size: 21),
                title: Text('${_date.year}年${_date.month}月${_date.day}日'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  widget.existing == null ? '保存${_type.label}' : '保存修改',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _displayAmount(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
