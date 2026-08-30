import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/expense_storage.dart';

class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 27,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 3),
        Text(subtitle!, style: const TextStyle(color: AppColors.muted)),
      ],
    ],
  );
}

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    this.onCalendar,
  });
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onCalendar;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                tooltip: '上个月',
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${month.year}年${month.month}月',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: onNext,
                tooltip: '下个月',
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
      if (onCalendar != null) ...[
        const SizedBox(width: 10),
        IconButton.outlined(
          onPressed: onCalendar,
          tooltip: '按日期查看',
          icon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
      ],
    ],
  );
}

class AmountSummary extends StatelessWidget {
  const AmountSummary({
    super.key,
    required this.label,
    required this.total,
    this.count,
  });
  final String label;
  final double total;
  final int? count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                '¥${formatAmount(total)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (count != null) ...[
          Container(width: 1, height: 52, color: AppColors.line),
          const SizedBox(width: 24),
          Text(
            '$count笔',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    ),
  );
}

/// 首页和统计页共用的收支摘要，避免两处计算和排版不一致。
class BalanceSummary extends StatelessWidget {
  const BalanceSummary({
    super.key,
    required this.income,
    required this.expense,
  });
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('本月结余', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '${balance < 0 ? '-' : ''}¥${formatAmount(balance.abs())}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(label: '收入', value: income, income: true),
              ),
              Container(width: 1, height: 42, color: AppColors.line),
              const SizedBox(width: 20),
              Expanded(
                child: _SummaryValue(
                  label: '支出',
                  value: expense,
                  income: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.income,
  });
  final String label;
  final double value;
  final bool income;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      const SizedBox(height: 3),
      Text(
        '¥${formatAmount(value)}',
        style: TextStyle(
          color: income ? AppColors.primary : AppColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
    ],
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.text = '这个月还没有记录'});
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          size: 44,
          color: AppColors.muted,
        ),
        const SizedBox(height: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
