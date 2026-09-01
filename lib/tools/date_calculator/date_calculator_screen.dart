import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_widgets.dart';

class DateCalculatorScreen extends StatefulWidget {
  const DateCalculatorScreen({super.key});

  @override
  State<DateCalculatorScreen> createState() => _DateCalculatorScreenState();
}

class _DateCalculatorScreenState extends State<DateCalculatorScreen> {
  DateTime start = DateUtils.dateOnly(DateTime.now());
  DateTime end = DateUtils.dateOnly(DateTime.now())
      .add(const Duration(days: 7));
  final dayController = TextEditingController(text: '30');

  @override
  void dispose() {
    dayController.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isStart) async {
    final initial = isStart ? start : end;
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (result != null) setState(() => isStart ? start = result : end = result);
  }

  String _date(DateTime value) => '${value.year}年${value.month}月${value.day}日';

  @override
  Widget build(BuildContext context) {
    final days = end.difference(start).inDays;
    // 限制在约一千年内，避免极端输入触发 DateTime 范围异常。
    final offset = (int.tryParse(dayController.text) ?? 0).clamp(
      -365000,
      365000,
    );
    return ToolPageScaffold(
      title: '日期计算',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '日期间隔',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _dateTile('开始日期', start, () => _pick(true)),
          _dateTile('结束日期', end, () => _pick(false)),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                '相差 ${days.abs()} 天${days < 0 ? '（结束日期更早）' : ''}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '日期推算',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: dayController,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'-?[0-9]*')),
            ],
            decoration: const InputDecoration(
              labelText: '增加或减少天数',
              helperText: '负数表示向前推算',
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: ListTile(
              title: const Text('推算结果'),
              subtitle: Text(
                _date(start.add(Duration(days: offset))),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTile(String label, DateTime value, VoidCallback tap) => Card(
    elevation: 0,
    child: ListTile(
      title: Text(label),
      subtitle: Text(_date(value)),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: tap,
    ),
  );
}
