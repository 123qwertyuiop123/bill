import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/widgets/tool_result_widgets.dart';
import '../../app/widgets/tool_widgets.dart';
import '../../core/app_theme.dart';
import 'loan_calculator_logic.dart';

/// 固定利率估算页面；输入和结果离开页面后不持久化。
class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen> {
  final _principal = TextEditingController(text: '100000');
  final _annualRate = TextEditingController(text: '4.2');
  final _months = TextEditingController(text: '36');
  LoanResult? _result;
  String? _error;

  @override
  void dispose() {
    _principal.dispose();
    _annualRate.dispose();
    _months.dispose();
    super.dispose();
  }

  void _invalidate() => setState(() {
    _result = null;
    _error = null;
  });

  void _calculate() => setState(() {
    _result = null;
    _error = null;
    try {
      _result = calculateLoan(
        principalText: _principal.text,
        annualRateText: _annualRate.text,
        monthsText: _months.text,
      );
    } on FormatException catch (error) {
      _error = error.message;
    }
  });

  @override
  Widget build(BuildContext context) => ToolPageScaffold(
    title: '贷款计算',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LoanInput(
                  fieldKey: const Key('loanPrincipal'),
                  controller: _principal,
                  label: '贷款本金',
                  suffix: '元',
                  onChanged: _invalidate,
                ),
                const SizedBox(height: 12),
                _LoanInput(
                  fieldKey: const Key('loanAnnualRate'),
                  controller: _annualRate,
                  label: '年利率',
                  suffix: '%',
                  onChanged: _invalidate,
                ),
                const SizedBox(height: 12),
                _LoanInput(
                  fieldKey: const Key('loanMonths'),
                  controller: _months,
                  label: '期数',
                  suffix: '月',
                  decimal: false,
                  onChanged: _invalidate,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('calculateLoan'),
                  onPressed: _calculate,
                  child: const Text('开始计算'),
                ),
              ],
            ),
          ),
        ),
        if (_result case final result?) ...[
          const SizedBox(height: 16),
          ToolResultCard(
            values: {
              '每月还款': '${formatLoanAmount(result.monthlyPayment)} 元',
              '总还款': '${formatLoanAmount(result.totalPayment)} 元',
              '总利息': '${formatLoanAmount(result.totalInterest)} 元',
            },
          ),
          const SizedBox(height: 12),
          CopyResultButton(
            text:
                '每月还款：${formatLoanAmount(result.monthlyPayment)} 元\n'
                '总还款：${formatLoanAmount(result.totalPayment)} 元\n'
                '总利息：${formatLoanAmount(result.totalInterest)} 元',
          ),
          const SizedBox(height: 12),
          _ScheduleCard(schedule: result.schedule),
        ] else ...[
          const SizedBox(height: 16),
          const Text('输入本金、固定年利率和期数后开始计算'),
        ],
        const SizedBox(height: 16),
        const Text(
          '采用固定年利率等额本息估算；结果不包含手续费、税费或利率变化，仅供参考。',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}

class _LoanInput extends StatelessWidget {
  const _LoanInput({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.onChanged,
    this.decimal = true,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String suffix;
  final VoidCallback onChanged;
  final bool decimal;

  @override
  Widget build(BuildContext context) => TextField(
    key: fieldKey,
    controller: controller,
    maxLength: maxLoanInputLength,
    maxLengthEnforcement: MaxLengthEnforcement.none,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    autocorrect: false,
    enableSuggestions: false,
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      counterText: '',
    ),
    onChanged: (_) => onChanged(),
  );
}

/// 明细使用独立惰性列表，600 期时也不会一次构建全部行。
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});
  final List<LoanPayment> schedule;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: ExpansionTile(
      key: const Key('loanSchedule'),
      title: Text('还款计划（${schedule.length} 期）'),
      children: [
        SizedBox(
          height: 360,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: schedule.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = schedule[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '第 ${item.period} 期',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        Text('还款 ${formatLoanAmount(item.payment)}'),
                        Text('本金 ${formatLoanAmount(item.principal)}'),
                        Text('利息 ${formatLoanAmount(item.interest)}'),
                        Text('余额 ${formatLoanAmount(item.balance)}'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
