import 'package:flutter/material.dart';

import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'age_calculator_logic.dart';

class AgeCalculatorScreen extends StatefulWidget {
  const AgeCalculatorScreen({super.key});

  @override
  State<AgeCalculatorScreen> createState() => _AgeCalculatorScreenState();
}

class _AgeCalculatorScreenState extends State<AgeCalculatorScreen> {
  DateTime birthDate = DateTime(1998, 6, 12);

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) {
      setState(() => birthDate = selected);
    }
  }

  String _date(DateTime value) => '${value.year}年${value.month}月${value.day}日';

  @override
  Widget build(BuildContext context) {
    final result = calculateAge(birthDate, DateTime.now())!;
    return ToolPageScaffold(
      title: '年龄计算',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            child: ListTile(
              title: const Text('出生日期'),
              subtitle: Text(_date(birthDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            color: AppColors.selected,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('当前周岁'),
                  Text(
                    '${result.years} 岁',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  title: const Text('已生活'),
                  trailing: Text(
                    '${result.daysLived} 天',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('下次生日'),
                  subtitle: Text(_date(result.nextBirthday)),
                  trailing: Text(
                    '${result.daysUntilBirthday} 天',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '年龄时间轴',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  for (final age in [10, 20, 30, 40, 50])
                    if (birthDate.year + age <= DateTime.now().year + 20)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 9,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Text('$age 岁'),
                            const Spacer(),
                            Text(
                              '${birthDate.year + age}年${birthDate.month}月${birthDate.day}日',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
