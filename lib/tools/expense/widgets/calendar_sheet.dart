import 'package:flutter/material.dart';

import '../controllers/expense_controller.dart';
import '../../../core/app_theme.dart';
import '../models/transaction_type.dart';
import '../services/expense_storage.dart';
import '../utils/date_utils.dart';

class CalendarSheet extends StatefulWidget {
  const CalendarSheet({
    super.key,
    required this.controller,
    required this.initialDate,
  });
  final ExpenseController controller;
  final DateTime initialDate;

  @override
  State<CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<CalendarSheet> {
  late DateTime selected = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final items = widget.controller.recordsForDay(selected);
    final balance = items.fold<double>(
      0,
      (sum, item) =>
          sum +
          (item.type == TransactionType.income ? item.amount : -item.amount),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                const Expanded(
                  child: Text(
                    '选择日期',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            CalendarDatePicker(
              initialDate: selected,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDateChanged: (value) => setState(() => selected = value),
            ),
            const Divider(),
            ListTile(
              title: Text(
                dayText(selected),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${items.length}笔收支 · 当天结余'),
              trailing: Text(
                '${balance < 0 ? '-' : '+'}¥${formatAmount(balance.abs())}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, selected),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('查看当天'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
