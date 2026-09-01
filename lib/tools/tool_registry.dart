import 'package:flutter/material.dart';

import '../app/models/tool_definition.dart';
import 'age_calculator/age_calculator_screen.dart';
import 'bmi_calculator/bmi_calculator_screen.dart';
import 'bill_split/bill_split_screen.dart';
import 'calculator/calculator_screen.dart';
import 'date_calculator/date_calculator_screen.dart';
import 'expense/expense_tool_screen.dart';
import 'list_processor/list_processor_screen.dart';
import 'password_generator/password_generator_screen.dart';
import 'percentage_calculator/percentage_calculator_screen.dart';
import 'qr_code/qr_code_screen.dart';
import 'random_decision/random_decision_screen.dart';
import 'stopwatch_timer/stopwatch_timer_screen.dart';
import 'tally_counter/tally_counter_screen.dart';
import 'text_diff/text_diff_screen.dart';
import 'text_tools/text_tools_screen.dart';
import 'unit_converter/unit_converter_screen.dart';

/// 所有工具只在这里注册一次，首页、分类、收藏和搜索共享同一数据源。
abstract final class ToolRegistry {
  static const tools = <ToolDefinition>[
    ToolDefinition(
      id: 'expense',
      title: '收支账本',
      description: '记录收支，自动同步月度 TXT',
      category: ToolCategory.life,
      icon: Icons.account_balance_wallet_outlined,
      builder: _expense,
    ),
    ToolDefinition(
      id: 'calculator',
      title: '计算器',
      description: '安全的基础四则运算',
      category: ToolCategory.calculation,
      icon: Icons.calculate_outlined,
      builder: _calculator,
    ),
    ToolDefinition(
      id: 'unit_converter',
      title: '单位换算',
      description: '长度、重量与温度换算',
      category: ToolCategory.calculation,
      icon: Icons.straighten_outlined,
      builder: _unitConverter,
    ),
    ToolDefinition(
      id: 'date_calculator',
      title: '日期计算',
      description: '日期间隔与日期推算',
      category: ToolCategory.calculation,
      icon: Icons.event_outlined,
      builder: _dateCalculator,
    ),
    ToolDefinition(
      id: 'password_generator',
      title: '密码生成',
      description: '使用安全随机数离线生成',
      category: ToolCategory.security,
      icon: Icons.password_outlined,
      builder: _passwordGenerator,
    ),
    ToolDefinition(
      id: 'text_tools',
      title: '文本工具',
      description: '统计、转换与清理文本',
      category: ToolCategory.text,
      icon: Icons.text_fields_outlined,
      builder: _textTools,
    ),
    ToolDefinition(
      id: 'qr_code',
      title: '二维码',
      description: '离线生成文字或网址二维码',
      category: ToolCategory.text,
      icon: Icons.qr_code_2_outlined,
      builder: _qrCode,
    ),
    ToolDefinition(
      id: 'bmi_calculator',
      title: 'BMI 计算',
      description: '计算身体质量指数',
      category: ToolCategory.life,
      icon: Icons.monitor_weight_outlined,
      builder: _bmiCalculator,
    ),
    ToolDefinition(
      id: 'stopwatch_timer',
      title: '秒表与倒计时',
      description: '精准计时与多次计次',
      category: ToolCategory.productivity,
      icon: Icons.timer_outlined,
      builder: _stopwatchTimer,
    ),
    ToolDefinition(
      id: 'percentage_calculator',
      title: '百分比计算',
      description: '百分比、增减与折扣计算',
      category: ToolCategory.calculation,
      icon: Icons.percent,
      builder: _percentageCalculator,
    ),
    ToolDefinition(
      id: 'bill_split',
      title: 'AA 分摊',
      description: '按人数平均分摊金额',
      category: ToolCategory.calculation,
      icon: Icons.group_outlined,
      builder: _billSplit,
    ),
    ToolDefinition(
      id: 'age_calculator',
      title: '年龄计算',
      description: '计算周岁与生日倒计时',
      category: ToolCategory.life,
      icon: Icons.cake_outlined,
      builder: _ageCalculator,
    ),
    ToolDefinition(
      id: 'random_decision',
      title: '随机决定',
      description: '随机数、骰子、硬币与抽签',
      category: ToolCategory.productivity,
      icon: Icons.shuffle,
      builder: _randomDecision,
    ),
    ToolDefinition(
      id: 'tally_counter',
      title: '计数器',
      description: '保存多个独立计数项目',
      category: ToolCategory.productivity,
      icon: Icons.exposure_plus_1_outlined,
      builder: _tallyCounter,
    ),
    ToolDefinition(
      id: 'text_diff',
      title: '文本对比',
      description: '逐行显示新增和删除内容',
      category: ToolCategory.text,
      icon: Icons.difference_outlined,
      builder: _textDiff,
    ),
    ToolDefinition(
      id: 'list_processor',
      title: '列表处理',
      description: '排序、去重、打乱与清理',
      category: ToolCategory.text,
      icon: Icons.format_list_bulleted,
      builder: _listProcessor,
    ),
  ];

  static Widget _expense(BuildContext context) => const ExpenseToolScreen();
  static Widget _calculator(BuildContext context) => const CalculatorScreen();
  static Widget _unitConverter(BuildContext context) =>
      const UnitConverterScreen();
  static Widget _dateCalculator(BuildContext context) =>
      const DateCalculatorScreen();
  static Widget _passwordGenerator(BuildContext context) =>
      const PasswordGeneratorScreen();
  static Widget _textTools(BuildContext context) => const TextToolsScreen();
  static Widget _qrCode(BuildContext context) => const QrCodeScreen();
  static Widget _bmiCalculator(BuildContext context) =>
      const BmiCalculatorScreen();
  static Widget _stopwatchTimer(BuildContext context) =>
      const StopwatchTimerScreen();
  static Widget _percentageCalculator(BuildContext context) =>
      const PercentageCalculatorScreen();
  static Widget _billSplit(BuildContext context) => const BillSplitScreen();
  static Widget _ageCalculator(BuildContext context) =>
      const AgeCalculatorScreen();
  static Widget _randomDecision(BuildContext context) =>
      const RandomDecisionScreen();
  static Widget _tallyCounter(BuildContext context) =>
      const TallyCounterScreen();
  static Widget _textDiff(BuildContext context) => const TextDiffScreen();
  static Widget _listProcessor(BuildContext context) =>
      const ListProcessorScreen();
}
