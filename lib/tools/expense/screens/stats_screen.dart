import 'package:flutter/material.dart';

import '../controllers/expense_controller.dart';
import '../../../core/app_theme.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../services/expense_storage.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.controller});
  final ExpenseController controller;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  TransactionType selectedType = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final totals = controller.categoryTotals(selectedType);
    final entries = totals.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final selectedTotal = selectedType == TransactionType.income
        ? controller.incomeTotal
        : controller.expenseTotal;
    final selectedCount = controller.monthRecords
        .where((item) => item.type == selectedType)
        .length;

    return ListView(
      key: const PageStorageKey('stats'),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      children: [
        const PageHeading(title: '收支统计'),
        const SizedBox(height: 20),
        MonthSelector(
          month: controller.month,
          onPrevious: () => controller.changeMonth(-1),
          onNext: () => controller.changeMonth(1),
        ),
        const SizedBox(height: 14),
        BalanceSummary(
          income: controller.incomeTotal,
          expense: controller.expenseTotal,
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('支出分析'),
              ),
              ButtonSegment(value: TransactionType.income, label: Text('收入分析')),
            ],
            selected: {selectedType},
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.selected,
              selectedForegroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            onSelectionChanged: (selection) =>
                setState(() => selectedType = selection.first),
          ),
        ),
        const SizedBox(height: 18),
        if (entries.isEmpty)
          SizedBox(
            height: 230,
            child: EmptyState(text: '本月还没有${selectedType.label}记录'),
          )
        else
          _CategoryList(entries: entries, total: selectedTotal),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            '${selectedType.label}共 $selectedCount 笔',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.entries, required this.total});
  final List<MapEntry<TransactionCategory, double>> entries;
  final double total;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < entries.length; index++) ...[
        _CategoryRow(entry: entries[index], total: total),
        if (index != entries.length - 1) const Divider(height: 1),
      ],
    ],
  );
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.entry, required this.total});
  final MapEntry<TransactionCategory, double> entry;
  final double total;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : entry.value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // 分类统计按最终设计只显示文字，不显示种类图标。
          SizedBox(
            width: 52,
            child: Text(
              entry.key.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${(ratio * 100).round()}%',
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                color: AppColors.primary,
                backgroundColor: AppColors.line,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: Text(
              '¥${formatAmount(entry.value)}',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
