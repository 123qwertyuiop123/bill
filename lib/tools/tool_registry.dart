import 'package:flutter/material.dart';

import '../app/models/tool_definition.dart';
import 'age_calculator/age_calculator_screen.dart';
import 'aspect_ratio_calculator/aspect_ratio_calculator_screen.dart';
import 'base64_tool/base64_tool_screen.dart';
import 'bmi_calculator/bmi_calculator_screen.dart';
import 'bill_split/bill_split_screen.dart';
import 'calculator/calculator_screen.dart';
import 'chmod_calculator/chmod_calculator_screen.dart';
import 'color_contrast/color_contrast_screen.dart';
import 'csv_json_converter/csv_json_converter_screen.dart';
import 'cron_parser/cron_parser_screen.dart';
import 'date_calculator/date_calculator_screen.dart';
import 'expense/expense_tool_screen.dart';
import 'hash_generator/hash_generator_screen.dart';
import 'http_status_reference/http_status_reference_screen.dart';
import 'image_optimizer/image_optimizer_screen.dart';
import 'ipv4_subnet/ipv4_subnet_screen.dart';
import 'json_tool/json_tool_screen.dart';
import 'jwt_viewer/jwt_viewer_screen.dart';
import 'list_processor/list_processor_screen.dart';
import 'luhn_checker/luhn_checker_screen.dart';
import 'markdown_preview/markdown_preview_screen.dart';
import 'mime_type_reference/mime_type_reference_screen.dart';
import 'number_base_converter/number_base_converter_screen.dart';
import 'ohms_law_calculator/ohms_law_calculator_screen.dart';
import 'password_generator/password_generator_screen.dart';
import 'percentage_calculator/percentage_calculator_screen.dart';
import 'placeholder_text/placeholder_text_screen.dart';
import 'port_reference/port_reference_screen.dart';
import 'qr_code/qr_code_screen.dart';
import 'random_decision/random_decision_screen.dart';
import 'regex_tester/regex_tester_screen.dart';
import 'roman_numeral_converter/roman_numeral_converter_screen.dart';
import 'statistics_calculator/statistics_calculator_screen.dart';
import 'stopwatch_timer/stopwatch_timer_screen.dart';
import 'tally_counter/tally_counter_screen.dart';
import 'text_diff/text_diff_screen.dart';
import 'text_tools/text_tools_screen.dart';
import 'timestamp_converter/timestamp_converter_screen.dart';
import 'totp_generator/totp_generator_screen.dart';
import 'unit_converter/unit_converter_screen.dart';
import 'unicode_inspector/unicode_inspector_screen.dart';
import 'url_tool/url_tool_screen.dart';
import 'uuid_generator/uuid_generator_screen.dart';
import 'xml_tool/xml_tool_screen.dart';
import 'yaml_json_converter/yaml_json_converter_screen.dart';

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
      description: '统计、转换与 HTML 实体处理',
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
    ToolDefinition(
      id: 'json_tool',
      title: 'JSON工具',
      description: '格式化、压缩与校验 JSON',
      category: ToolCategory.text,
      icon: Icons.data_object,
      builder: _jsonTool,
    ),
    ToolDefinition(
      id: 'base64_tool',
      title: 'Base64',
      description: '离线进行文本编码与解码',
      category: ToolCategory.text,
      icon: Icons.code_outlined,
      builder: _base64Tool,
    ),
    ToolDefinition(
      id: 'url_tool',
      title: 'URL 编解码',
      description: '编码、解码与查询参数解析',
      category: ToolCategory.text,
      icon: Icons.link,
      builder: _urlTool,
    ),
    ToolDefinition(
      id: 'timestamp_converter',
      title: 'Unix 时间戳',
      description: '时间戳与本地日期互相转换',
      category: ToolCategory.calculation,
      icon: Icons.access_time,
      builder: _timestampConverter,
    ),
    ToolDefinition(
      id: 'number_base_converter',
      title: '进制转换',
      description: '二、八、十、十六进制互转',
      category: ToolCategory.calculation,
      icon: Icons.numbers,
      builder: _numberBaseConverter,
    ),
    ToolDefinition(
      id: 'uuid_generator',
      title: 'UUID 生成',
      description: '安全随机生成 UUID v4',
      category: ToolCategory.security,
      icon: Icons.fingerprint,
      builder: _uuidGenerator,
    ),
    ToolDefinition(
      id: 'regex_tester',
      title: '正则测试',
      description: '安全测试表达式与匹配位置',
      category: ToolCategory.text,
      icon: Icons.data_array,
      builder: _regexTester,
    ),
    ToolDefinition(
      id: 'hash_generator',
      title: '哈希生成',
      description: '文本、文件摘要与 HMAC',
      category: ToolCategory.security,
      icon: Icons.tag,
      builder: _hashGenerator,
    ),
    ToolDefinition(
      id: 'color_contrast',
      title: '颜色与对比度',
      description: '检查文字颜色的 WCAG 对比度',
      category: ToolCategory.productivity,
      icon: Icons.contrast,
      builder: _colorContrast,
    ),
    ToolDefinition(
      id: 'jwt_viewer',
      title: 'JWT 查看',
      description: '离线查看令牌头部与载荷',
      category: ToolCategory.security,
      icon: Icons.policy_outlined,
      builder: _jwtViewer,
    ),
    ToolDefinition(
      id: 'csv_json_converter',
      title: 'CSV/JSON 转换',
      description: 'CSV 表格与 JSON 对象数组互转',
      category: ToolCategory.text,
      icon: Icons.table_chart_outlined,
      builder: _csvJsonConverter,
    ),
    ToolDefinition(
      id: 'cron_parser',
      title: 'Cron 解析',
      description: '解析计划含义与后续执行时间',
      category: ToolCategory.productivity,
      icon: Icons.schedule_outlined,
      builder: _cronParser,
    ),
    ToolDefinition(
      id: 'placeholder_text',
      title: '占位文本',
      description: '生成中文或拉丁排版示例',
      category: ToolCategory.text,
      icon: Icons.notes_outlined,
      builder: _placeholderText,
    ),
    ToolDefinition(
      id: 'ipv4_subnet',
      title: 'IPv4 子网计算',
      description: '离线计算网络范围与掩码',
      category: ToolCategory.calculation,
      icon: Icons.lan_outlined,
      builder: _ipv4Subnet,
    ),
    ToolDefinition(
      id: 'chmod_calculator',
      title: '权限计算',
      description: 'Unix 权限勾选与八进制互转',
      category: ToolCategory.calculation,
      icon: Icons.rule_outlined,
      builder: _chmodCalculator,
    ),
    ToolDefinition(
      id: 'luhn_checker',
      title: 'Luhn 校验',
      description: '检查数字序列或生成校验位',
      category: ToolCategory.calculation,
      icon: Icons.fact_check_outlined,
      builder: _luhnChecker,
    ),
    ToolDefinition(
      id: 'markdown_preview',
      title: 'Markdown 预览',
      description: '安全预览常用 Markdown 排版',
      category: ToolCategory.text,
      icon: Icons.preview_outlined,
      builder: _markdownPreview,
    ),
    ToolDefinition(
      id: 'http_status_reference',
      title: 'HTTP 状态码',
      description: '离线查询状态含义与处理建议',
      category: ToolCategory.productivity,
      icon: Icons.http_outlined,
      builder: _httpStatusReference,
    ),
    ToolDefinition(
      id: 'mime_type_reference',
      title: 'MIME 类型',
      description: '按扩展名或媒体类型离线查询',
      category: ToolCategory.productivity,
      icon: Icons.description_outlined,
      builder: _mimeTypeReference,
    ),
    ToolDefinition(
      id: 'image_optimizer',
      title: '图片优化',
      description: '离线压缩、缩放与格式转换',
      category: ToolCategory.productivity,
      icon: Icons.photo_size_select_large_outlined,
      builder: _imageOptimizer,
    ),
    ToolDefinition(
      id: 'aspect_ratio_calculator',
      title: '宽高比计算',
      description: '约分比例并等比换算尺寸',
      category: ToolCategory.calculation,
      icon: Icons.aspect_ratio_outlined,
      builder: _aspectRatioCalculator,
    ),
    ToolDefinition(
      id: 'yaml_json_converter',
      title: 'YAML/JSON 转换',
      description: '离线双向转换 YAML 与 JSON',
      category: ToolCategory.text,
      icon: Icons.swap_horiz_outlined,
      builder: _yamlJsonConverter,
    ),
    ToolDefinition(
      id: 'xml_tool',
      title: 'XML 工具',
      description: '安全格式化、压缩与校验 XML',
      category: ToolCategory.text,
      icon: Icons.code_outlined,
      builder: _xmlTool,
    ),
    ToolDefinition(
      id: 'unicode_inspector',
      title: 'Unicode 检查',
      description: '查看字符码点与 UTF 编码',
      category: ToolCategory.text,
      icon: Icons.translate_outlined,
      builder: _unicodeInspector,
    ),
    ToolDefinition(
      id: 'port_reference',
      title: '端口号参考',
      description: '离线查询常用 TCP/UDP 端口',
      category: ToolCategory.productivity,
      icon: Icons.dns_outlined,
      builder: _portReference,
    ),
    ToolDefinition(
      id: 'totp_generator',
      title: 'TOTP 验证码',
      description: '用 Base32 密钥离线生成动态验证码',
      category: ToolCategory.security,
      icon: Icons.verified_user_outlined,
      builder: _totpGenerator,
    ),
    ToolDefinition(
      id: 'ohms_law_calculator',
      title: '欧姆定律',
      description: '从两个电气量计算其余结果',
      category: ToolCategory.calculation,
      icon: Icons.electric_bolt_outlined,
      builder: _ohmsLawCalculator,
    ),
    ToolDefinition(
      id: 'statistics_calculator',
      title: '统计计算',
      description: '计算数值列表的描述统计',
      category: ToolCategory.calculation,
      icon: Icons.query_stats_outlined,
      builder: _statisticsCalculator,
    ),
    ToolDefinition(
      id: 'roman_numeral_converter',
      title: '罗马数字',
      description: '十进制整数与罗马数字互转',
      category: ToolCategory.calculation,
      icon: Icons.history_edu_outlined,
      builder: _romanNumeralConverter,
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
  static Widget _jsonTool(BuildContext context) => const JsonToolScreen();
  static Widget _base64Tool(BuildContext context) => const Base64ToolScreen();
  static Widget _urlTool(BuildContext context) => const UrlToolScreen();
  static Widget _timestampConverter(BuildContext context) =>
      const TimestampConverterScreen();
  static Widget _numberBaseConverter(BuildContext context) =>
      const NumberBaseConverterScreen();
  static Widget _uuidGenerator(BuildContext context) =>
      const UuidGeneratorScreen();
  static Widget _regexTester(BuildContext context) => const RegexTesterScreen();
  static Widget _hashGenerator(BuildContext context) =>
      const HashGeneratorScreen();
  static Widget _colorContrast(BuildContext context) =>
      const ColorContrastScreen();
  static Widget _jwtViewer(BuildContext context) => const JwtViewerScreen();
  static Widget _csvJsonConverter(BuildContext context) =>
      const CsvJsonConverterScreen();
  static Widget _cronParser(BuildContext context) => const CronParserScreen();
  static Widget _placeholderText(BuildContext context) =>
      const PlaceholderTextScreen();
  static Widget _ipv4Subnet(BuildContext context) => const Ipv4SubnetScreen();
  static Widget _chmodCalculator(BuildContext context) =>
      const ChmodCalculatorScreen();
  static Widget _luhnChecker(BuildContext context) => const LuhnCheckerScreen();
  static Widget _markdownPreview(BuildContext context) =>
      const MarkdownPreviewScreen();
  static Widget _httpStatusReference(BuildContext context) =>
      const HttpStatusReferenceScreen();
  static Widget _mimeTypeReference(BuildContext context) =>
      const MimeTypeReferenceScreen();
  static Widget _imageOptimizer(BuildContext context) =>
      const ImageOptimizerScreen();
  static Widget _aspectRatioCalculator(BuildContext context) =>
      const AspectRatioCalculatorScreen();
  static Widget _yamlJsonConverter(BuildContext context) =>
      const YamlJsonConverterScreen();
  static Widget _xmlTool(BuildContext context) => const XmlToolScreen();
  static Widget _unicodeInspector(BuildContext context) =>
      const UnicodeInspectorScreen();
  static Widget _portReference(BuildContext context) =>
      const PortReferenceScreen();
  static Widget _totpGenerator(BuildContext context) =>
      const TotpGeneratorScreen();
  static Widget _ohmsLawCalculator(BuildContext context) =>
      const OhmsLawCalculatorScreen();
  static Widget _statisticsCalculator(BuildContext context) =>
      const StatisticsCalculatorScreen();
  static Widget _romanNumeralConverter(BuildContext context) =>
      const RomanNumeralConverterScreen();
}
