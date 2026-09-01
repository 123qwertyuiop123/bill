import 'package:flutter/material.dart';

import '../controllers/expense_controller.dart';
import '../../../core/app_theme.dart';
import '../models/expense_record.dart';
import '../models/transaction_type.dart';
import '../services/expense_storage.dart';
import '../utils/date_utils.dart';
import '../widgets/common_widgets.dart';
import '../widgets/expense_form_sheet.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({
    super.key,
    required this.controller,
    required this.day,
  });
  final ExpenseController controller;
  final DateTime day;

  Future<void> _edit(BuildContext context, ExpenseRecord record) async {
    final changed = await showModalBottomSheet<ExpenseRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFormSheet(existing: record),
    );
    if (changed == null || !context.mounted) return;
    final ok = await controller.update(changed);
    if (!context.mounted) return;
    _showResult(context, ok ? '修改已保存' : controller.error ?? '修改失败');
  }

  Future<void> _delete(BuildContext context, ExpenseRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这笔记录？'),
        content: Text(
          '${record.reason}  ${record.type == TransactionType.income ? '+' : '-'}¥${formatAmount(record.amount)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await controller.remove(record);
    if (!context.mounted) return;
    _showResult(context, ok ? '记录已删除' : controller.error ?? '删除失败');
  }

  Future<void> _add(BuildContext context) async {
    final record = await showModalBottomSheet<ExpenseRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFormSheet(initialDate: day),
    );
    if (record == null || !context.mounted) return;
    final ok = await controller.add(record);
    if (!context.mounted) return;
    _showResult(context, ok ? '记录已保存' : controller.error ?? '保存失败');
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final items = controller.recordsForDay(day);
      final income = items
          .where((item) => item.type == TransactionType.income)
          .fold<double>(0, (sum, item) => sum + item.amount);
      final expense = items
          .where((item) => item.type == TransactionType.expense)
          .fold<double>(0, (sum, item) => sum + item.amount);
      return Scaffold(
        appBar: AppBar(
          title: Text(dayText(day)),
          centerTitle: true,
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
          children: [
            Text(
              weekdayText(day),
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            BalanceSummary(income: income, expense: expense),
            const SizedBox(height: 26),
            const SectionHeading(title: '收支明细'),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const SizedBox(height: 260, child: EmptyState(text: '当天还没有收支记录'))
            else
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _DayExpenseRow(
                        record: items[index],
                        onEdit: () => _edit(context, items[index]),
                        onDelete: () => _delete(context, items[index]),
                      ),
                      if (index != items.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: OutlinedButton.icon(
            onPressed: controller.saving ? null : () => _add(context),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('添加当天收支'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      );
    },
  );
}

class _DayExpenseRow extends StatelessWidget {
  const _DayExpenseRow({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });
  final ExpenseRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(
      record.reason,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      record.type == TransactionType.income ? '收入' : record.category.label,
      style: const TextStyle(color: AppColors.muted),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${record.type == TransactionType.income ? '+' : '-'}¥${formatAmount(record.amount)}',
          style: TextStyle(
            color: record.type == TransactionType.income
                ? AppColors.primary
                : AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: '更多操作',
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('编辑'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('删除'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

void _showResult(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
