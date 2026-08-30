import 'package:flutter/material.dart';

import '../controllers/expense_controller.dart';
import '../core/app_theme.dart';
import '../models/expense_record.dart';
import '../models/ledger_file.dart';
import '../models/transaction_type.dart';
import '../services/expense_storage.dart';
import '../utils/date_utils.dart';
import '../widgets/calendar_sheet.dart';
import '../widgets/common_widgets.dart';
import 'day_detail_screen.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key, required this.controller});
  final ExpenseController controller;

  Future<void> _openCalendar(BuildContext context) async {
    final date = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          CalendarSheet(controller: controller, initialDate: controller.month),
    );
    if (date != null && context.mounted) _openDay(context, date);
  }

  void _openDay(BuildContext context, DateTime day) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DayDetailScreen(controller: controller, day: day),
      ),
    );
  }

  Future<void> _renameFile(BuildContext context) async {
    final current = controller.filePath.split(RegExp(r'[/\\]')).last;
    var editedName = current.toLowerCase().endsWith('.txt')
        ? current.substring(0, current.length - 4)
        : current;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('修改 TXT 文件名'),
        content: TextFormField(
          initialValue: editedName,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: '文件名',
            suffixText: '.txt',
            helperText: '将自动同步到对应年份文件夹',
          ),
          onChanged: (value) => editedName = value,
          onFieldSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, editedName),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (name == null || !context.mounted) return;
    final success = await controller.renameMonthFile(name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? controller.publicSyncError ?? '文件名已修改并自动同步'
                : controller.error ?? '修改失败',
          ),
        ),
      );
  }

  Future<void> _createFile(BuildContext context) async {
    var name = '';
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建 TXT'),
        content: TextFormField(
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: '文件名',
            suffixText: '.txt',
            helperText: '新文件从空白账本开始',
          ),
          onChanged: (value) => name = value,
          onFieldSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, name),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    final success = await controller.createMonthFile(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? controller.publicSyncError ?? 'TXT 已创建并切换'
                : controller.error ?? '创建失败',
          ),
        ),
      );
  }

  Future<void> _switchFile(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '切换 TXT',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.monthFiles.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final file = controller.monthFiles[index];
                    final isSelected = file.id == controller.selectedFileId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined),
                      title: Text(file.fileName),
                      subtitle: Text(file.isDefault ? '默认 TXT' : '独立 TXT'),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.pop(sheetContext, file.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _createFile(context);
                  },
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('新建 TXT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await controller.selectMonthFile(selected);
    }
  }

  Future<void> _chooseLineFormat(BuildContext context) async {
    final current = controller.selectedFile?.lineFormat ?? LedgerLineFormat.day;
    final selected = await showDialog<LedgerLineFormat>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('选择每行开头格式'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, LedgerLineFormat.day),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('日期开头（默认）'),
              subtitle: const Text('1日:午饭:18.8'),
              trailing: current == LedgerLineFormat.day
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
            ),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(dialogContext, LedgerLineFormat.fullDate),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('完整日期开头'),
              subtitle: const Text('2026年8月1日:午饭:18.8'),
              trailing: current == LedgerLineFormat.fullDate
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
            ),
          ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;
    final success = await controller.setSelectedFileLineFormat(selected);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? controller.publicSyncError ?? 'TXT 行首格式已更新'
                : controller.error ?? '格式设置失败',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final groups = <DateTime, List<ExpenseRecord>>{};
    for (final item in controller.monthRecords) {
      final day = DateTime(item.date.year, item.date.month, item.date.day);
      groups.putIfAbsent(day, () => []).add(item);
    }
    return CustomScrollView(
      key: const PageStorageKey('ledger'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          sliver: SliverList.list(
            children: [
              const PageHeading(title: '我的账本', subtitle: '记录每一笔收支'),
              const SizedBox(height: 20),
              MonthSelector(
                month: controller.month,
                onPrevious: () => controller.changeMonth(-1),
                onNext: () => controller.changeMonth(1),
                onCalendar: () => _openCalendar(context),
              ),
              const SizedBox(height: 14),
              BalanceSummary(
                income: controller.incomeTotal,
                expense: controller.expenseTotal,
              ),
              const SizedBox(height: 12),
              _FileStatus(
                path: controller.filePath,
                publicPath: controller.publicPath,
                syncError: controller.publicSyncError,
                lineFormat:
                    controller.selectedFile?.lineFormat ?? LedgerLineFormat.day,
                onSwitch: controller.saving ? null : () => _switchFile(context),
                onCreate: controller.saving ? null : () => _createFile(context),
                onRename: controller.saving ? null : () => _renameFile(context),
                onFormat: controller.saving
                    ? null
                    : () => _chooseLineFormat(context),
              ),
              const SizedBox(height: 24),
              const SectionHeading(title: '按日查看'),
            ],
          ),
        ),
        if (groups.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: EmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverList.separated(
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = groups.entries.elementAt(index);
                return _DayGroup(
                  day: entry.key,
                  items: entry.value,
                  onTap: () => _openDay(context, entry.key),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _FileStatus extends StatelessWidget {
  const _FileStatus({
    required this.path,
    required this.publicPath,
    required this.syncError,
    required this.lineFormat,
    required this.onSwitch,
    required this.onCreate,
    required this.onRename,
    required this.onFormat,
  });
  final String path;
  final String publicPath;
  final String? syncError;
  final LedgerLineFormat lineFormat;
  final VoidCallback? onSwitch;
  final VoidCallback? onCreate;
  final VoidCallback? onRename;
  final VoidCallback? onFormat;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.line),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onSwitch,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.description_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.isEmpty
                        ? defaultMonthFileName(DateTime.now())
                        : path.split(RegExp(r'[/\\]')).last,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '自动保存 · ${lineFormat.label} · 点击切换 TXT',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    syncError ??
                        (publicPath.isEmpty
                            ? 'Download/bill/年份'
                            : publicPath.replaceFirst(
                                '/storage/emulated/0/',
                                '',
                              )),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: syncError == null
                          ? AppColors.muted
                          : AppColors.danger,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onFormat,
              tooltip: '设置行首格式',
              icon: const Icon(Icons.format_align_left_outlined),
            ),
            IconButton(
              onPressed: onCreate,
              tooltip: '新建 TXT',
              icon: const Icon(Icons.note_add_outlined),
            ),
            IconButton(
              onPressed: onRename,
              tooltip: '修改文件名',
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.muted,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.day,
    required this.items,
    required this.onTap,
  });
  final DateTime day;
  final List<ExpenseRecord> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final balance = items.fold<double>(
      0,
      (sum, item) =>
          sum +
          (item.type == TransactionType.income ? item.amount : -item.amount),
    );
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${dayText(day)}  ${shortWeekdayText(day)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${items.length}笔  ${balance < 0 ? '-' : '+'}¥${formatAmount(balance.abs())}',
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          for (var index = 0; index < items.length; index++) ...[
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              title: Text(
                items[index].reason,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                items[index].type == TransactionType.income
                    ? '收入'
                    : items[index].category.label,
              ),
              trailing: Text(
                '${items[index].type == TransactionType.income ? '+' : '-'}¥${formatAmount(items[index].amount)}',
                style: TextStyle(
                  color: items[index].type == TransactionType.income
                      ? AppColors.primary
                      : AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: onTap,
            ),
            if (index != items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
