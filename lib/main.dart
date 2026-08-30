import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'expense_storage.dart';

const green = Color(0xff246b4a);
const ink = Color(0xff202622);
const muted = Color(0xff717a74);
const canvas = Color(0xfff7f8f5);
const line = Color(0xffe5e9e5);

void main() => runApp(const CostBookApp());

class CostBookApp extends StatelessWidget {
  const CostBookApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '消费记录',
    theme: ThemeData(
      useMaterial3: true,
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC'],
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(seedColor: green),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xfff3f5f2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    home: const ExpensePage(),
  );
}

enum ExpenseCategory { food, transport, shopping, housing, health, other }

extension CategoryView on ExpenseCategory {
  String get label => switch (this) {
    ExpenseCategory.food => '餐饮',
    ExpenseCategory.transport => '交通',
    ExpenseCategory.shopping => '购物',
    ExpenseCategory.housing => '居住',
    ExpenseCategory.health => '医疗',
    ExpenseCategory.other => '其他',
  };
  IconData get icon => switch (this) {
    ExpenseCategory.food => Icons.restaurant_outlined,
    ExpenseCategory.transport => Icons.directions_bus_outlined,
    ExpenseCategory.shopping => Icons.shopping_bag_outlined,
    ExpenseCategory.housing => Icons.home_outlined,
    ExpenseCategory.health => Icons.local_hospital_outlined,
    ExpenseCategory.other => Icons.more_horiz,
  };
  Color get color => switch (this) {
    ExpenseCategory.food => const Color(0xffd9823b),
    ExpenseCategory.transport => const Color(0xff477fb8),
    ExpenseCategory.shopping => const Color(0xff8069b2),
    ExpenseCategory.housing => const Color(0xff59906b),
    ExpenseCategory.health => const Color(0xffc25f65),
    ExpenseCategory.other => const Color(0xff8a918c),
  };

  static ExpenseCategory parse(String value) =>
      ExpenseCategory.values.firstWhere(
        (item) => item.name == value,
        orElse: () => ExpenseCategory.other,
      );
}

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});
  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final storage = ExpenseStorage();
  List<ExpenseRecord> records = [];
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  String filePath = '';
  int page = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await storage.load();
    await storage.save(saved);
    final path = await storage.monthFilePath(month);
    if (!mounted) return;
    setState(() {
      records = saved;
      filePath = path;
      loading = false;
    });
  }

  Future<void> _moveMonth(int offset) async {
    final next = DateTime(month.year, month.month + offset);
    final path = await storage.writeMonth(records, next);
    if (!mounted) return;
    setState(() {
      month = next;
      filePath = path;
    });
  }

  Future<void> _add() async {
    final result = await showModalBottomSheet<ExpenseRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseSheet(),
    );
    if (result == null) return;
    records.add(result);
    await storage.save(records);
    final newMonth = DateTime(result.date.year, result.date.month);
    final path = await storage.monthFilePath(newMonth);
    if (!mounted) return;
    setState(() {
      month = newMonth;
      filePath = path;
      page = 0;
    });
  }

  Future<void> _remove(ExpenseRecord record) async {
    setState(() => records.removeWhere((item) => item.id == record.id));
    await storage.save(records);
    await storage.writeMonth(
      records,
      DateTime(record.date.year, record.date.month),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items =
        records
            .where(
              (item) =>
                  item.date.year == month.year &&
                  item.date.month == month.month,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : IndexedStack(
                index: page,
                children: [
                  LedgerView(
                    month: month,
                    items: items,
                    total: total,
                    filePath: filePath,
                    previous: () => _moveMonth(-1),
                    next: () => _moveMonth(1),
                    remove: _remove,
                  ),
                  StatsView(
                    month: month,
                    items: items,
                    total: total,
                    previous: () => _moveMonth(-1),
                    next: () => _moveMonth(1),
                  ),
                ],
              ),
      ),
      floatingActionButton: page == 0
          ? FloatingActionButton.extended(
              onPressed: _add,
              elevation: 1,
              backgroundColor: green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 21),
              label: const Text(
                '记一笔',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: page,
        indicatorColor: const Color(0xffdfece4),
        onDestinationSelected: (value) => setState(() => page = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: green),
            label: '账本',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart, color: green),
            label: '统计',
          ),
        ],
      ),
    );
  }
}

class LedgerView extends StatelessWidget {
  const LedgerView({
    super.key,
    required this.month,
    required this.items,
    required this.total,
    required this.filePath,
    required this.previous,
    required this.next,
    required this.remove,
  });
  final DateTime month;
  final List<ExpenseRecord> items;
  final double total;
  final String filePath;
  final VoidCallback previous, next;
  final ValueChanged<ExpenseRecord> remove;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const PageStorageKey('ledger'),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
        sliver: SliverList.list(
          children: [
            const PageTitle(title: '我的账本', subtitle: '简单记下每一笔消费'),
            const SizedBox(height: 20),
            MonthBar(month: month, previous: previous, next: next),
            const SizedBox(height: 12),
            SummaryCard(total: total, count: items.length),
            const SizedBox(height: 12),
            FileRow(filePath: filePath),
            const SizedBox(height: 24),
            SectionTitle(title: '消费明细', trailing: '${items.length} 笔'),
          ],
        ),
      ),
      if (items.isEmpty)
        const SliverFillRemaining(hasScrollBody: false, child: EmptyState())
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 60),
            itemBuilder: (_, index) {
              final item = items[index];
              return ExpenseTile(record: item, onDelete: () => remove(item));
            },
          ),
        ),
    ],
  );
}

class StatsView extends StatelessWidget {
  const StatsView({
    super.key,
    required this.month,
    required this.items,
    required this.total,
    required this.previous,
    required this.next,
  });
  final DateTime month;
  final List<ExpenseRecord> items;
  final double total;
  final VoidCallback previous, next;

  @override
  Widget build(BuildContext context) {
    final values = <ExpenseCategory, double>{
      for (final category in ExpenseCategory.values) category: 0,
    };
    for (final item in items) {
      final category = CategoryView.parse(item.category);
      values[category] = values[category]! + item.amount;
    }
    final visible = values.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      key: const PageStorageKey('stats'),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
      children: [
        const PageTitle(title: '消费统计', subtitle: '了解钱花在了哪里'),
        const SizedBox(height: 20),
        MonthBar(month: month, previous: previous, next: next),
        const SizedBox(height: 20),
        if (visible.isEmpty)
          const SizedBox(height: 380, child: EmptyState())
        else ...[
          RepaintBoundary(
            child: SizedBox(
              height: 210,
              child: CustomPaint(
                painter: DonutPainter(values: visible),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '本月消费',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '¥${formatAmount(total)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle(title: '分类明细'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: line),
            ),
            child: Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  CategoryRow(entry: visible[index], total: total),
                  if (index != visible.length - 1)
                    const Divider(height: 1, indent: 54),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: ink,
          fontSize: 27,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
        ),
      ),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: muted, fontSize: 14)),
    ],
  );
}

class MonthBar extends StatelessWidget {
  const MonthBar({
    super.key,
    required this.month,
    required this.previous,
    required this.next,
  });
  final DateTime month;
  final VoidCallback previous, next;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: previous,
          icon: const Icon(Icons.chevron_left),
          tooltip: '上个月',
        ),
        Expanded(
          child: Text(
            '${month.year}年 ${month.month}月',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: next,
          icon: const Icon(Icons.chevron_right),
          tooltip: '下个月',
        ),
      ],
    ),
  );
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.total, required this.count});
  final double total;
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: green,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '本月消费',
                style: TextStyle(color: Color(0xffd9e8df), fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                '¥${formatAmount(total)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$count 笔',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class FileRow extends StatelessWidget {
  const FileRow({super.key, required this.filePath});
  final String filePath;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.description_outlined, color: green),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                filePath.split(RegExp(r'[/\\]')).last,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              const Text('已自动保存', style: TextStyle(color: muted, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.check_circle_outline, color: green, size: 20),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.trailing});
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
        Text(trailing!, style: const TextStyle(color: muted, fontSize: 13)),
    ],
  );
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.record, required this.onDelete});
  final ExpenseRecord record;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final category = CategoryView.parse(record.category);
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: const ColoredBox(
        color: Color(0xffc45c62),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.delete_outline, color: Colors.white),
          ),
        ),
      ),
      child: ColoredBox(
        color: Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: category.color.withValues(alpha: .11),
            foregroundColor: category.color,
            child: Icon(category.icon, size: 21),
          ),
          title: Text(
            record.reason,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${record.date.day}日 · ${category.label}',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          trailing: Text(
            '¥${formatAmount(record.amount)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key, required this.entry, required this.total});
  final MapEntry<ExpenseCategory, double> entry;
  final double total;
  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : entry.value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(entry.key.icon, color: entry.key.color, size: 21),
          const SizedBox(width: 12),
          SizedBox(
            width: 42,
            child: Text(
              entry.key.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                color: entry.key.color,
                backgroundColor: const Color(0xffedf0ed),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
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

class DonutPainter extends CustomPainter {
  DonutPainter({required this.values});
  final List<MapEntry<ExpenseCategory, double>> values;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, entry) => sum + entry.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .38;
    const stroke = 24.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    for (final entry in values) {
      final sweep = total == 0 ? 0.0 : entry.value / total * math.pi * 2;
      paint.color = entry.key.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) =>
      oldDelegate.values != values;
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.receipt_long_outlined, size: 46, color: Color(0xff98a099)),
        SizedBox(height: 10),
        Text('这个月还没有记录', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('点击“记一笔”开始记录', style: TextStyle(color: muted, fontSize: 13)),
      ],
    ),
  );
}

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});
  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final formKey = GlobalKey<FormState>();
  final reason = TextEditingController();
  final amount = TextEditingController();
  DateTime date = DateTime.now();
  ExpenseCategory category = ExpenseCategory.food;

  @override
  void dispose() {
    reason.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '选择消费日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (value != null) setState(() => date = value);
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ExpenseRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        reason: reason.text.trim(),
        amount: double.parse(amount.text.trim()),
        date: date,
        category: category.name,
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
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    child: SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xffd8ddd9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '记一笔消费',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextFormField(
              key: const Key('reasonField'),
              controller: reason,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '消费原因',
                hintText: '例如：午饭',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '请输入消费原因' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('amountField'),
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
              ),
              validator: (value) =>
                  (double.tryParse(value?.trim() ?? '') ?? 0) <= 0
                  ? '请输入正确的金额'
                  : null,
            ),
            const SizedBox(height: 16),
            const Text('消费种类', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.values
                  .map(
                    (item) => ChoiceChip(
                      avatar: Icon(item.icon, size: 17),
                      label: Text(item.label),
                      selected: category == item,
                      showCheckmark: false,
                      selectedColor: const Color(0xffdceae2),
                      side: BorderSide(color: category == item ? green : line),
                      onSelected: (_) => setState(() => category = item),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined, size: 21),
              title: Text('${date.year}年${date.month}月${date.day}日'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '保存消费',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
