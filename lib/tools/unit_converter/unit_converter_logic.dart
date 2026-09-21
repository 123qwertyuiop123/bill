const maxUnitInputLength = 64;
const maxUnitMagnitude = 1e100;

const conversionUnits = <String, List<String>>{
  '长度': ['毫米', '厘米', '米', '千米'],
  '重量': ['克', '千克', '吨'],
  '温度': ['摄氏度', '华氏度', '开尔文'],
  '数据容量': [
    '比特',
    '字节',
    'KB（十进制）',
    'MB（十进制）',
    'GB（十进制）',
    'TB（十进制）',
    'KiB（二进制）',
    'MiB（二进制）',
    'GiB（二进制）',
    'TiB（二进制）',
  ],
};

const defaultUnitPairs = <String, (String, String)>{
  '长度': ('米', '千米'),
  '重量': ('千克', '克'),
  '温度': ('摄氏度', '华氏度'),
  '数据容量': ('GB（十进制）', 'GiB（二进制）'),
};

const _factors = <String, double>{
  '毫米': .001,
  '厘米': .01,
  '米': 1,
  '千米': 1000,
  '克': .001,
  '千克': 1,
  '吨': 1000,
  '比特': .125,
  '字节': 1,
  'KB（十进制）': 1e3,
  'MB（十进制）': 1e6,
  'GB（十进制）': 1e9,
  'TB（十进制）': 1e12,
  'KiB（二进制）': 1024,
  'MiB（二进制）': 1048576,
  'GiB（二进制）': 1073741824,
  'TiB（二进制）': 1099511627776,
};

class UnitConversionResult {
  const UnitConversionResult({this.value, this.error});

  final double? value;
  final String? error;
  bool get isSuccess => error == null;
}

/// 单位换算只处理同类型单位，并对非有限数和极大输入提前拒绝。
UnitConversionResult convertUnit({
  required String input,
  required String kind,
  required String from,
  required String to,
}) {
  if (input.trim().isEmpty) {
    return const UnitConversionResult(error: '请输入需要换算的数值');
  }
  if (input.length > maxUnitInputLength) {
    return const UnitConversionResult(error: '数值输入不能超过 64 个字符');
  }
  final value = double.tryParse(input.trim());
  if (value == null || !value.isFinite) {
    return const UnitConversionResult(error: '请输入有效的有限数值');
  }
  if (value.abs() > maxUnitMagnitude) {
    return const UnitConversionResult(error: '数值绝对值不能超过 10¹⁰⁰');
  }
  if (kind == '数据容量' && value < 0) {
    return const UnitConversionResult(error: '数据容量不能小于 0');
  }
  final units = conversionUnits[kind];
  if (units == null || !units.contains(from) || !units.contains(to)) {
    return const UnitConversionResult(error: '请选择同一类型中的有效单位');
  }
  final converted = kind == '温度'
      ? _convertTemperature(value, from, to)
      : value * _factors[from]! / _factors[to]!;
  if (!converted.isFinite) {
    return const UnitConversionResult(error: '换算结果超出可显示范围');
  }
  return UnitConversionResult(value: converted);
}

double _convertTemperature(double value, String from, String to) {
  final celsius = switch (from) {
    '华氏度' => (value - 32) * 5 / 9,
    '开尔文' => value - 273.15,
    _ => value,
  };
  return switch (to) {
    '华氏度' => celsius * 9 / 5 + 32,
    '开尔文' => celsius + 273.15,
    _ => celsius,
  };
}

String formatUnitValue(double value) {
  final absolute = value.abs();
  if (absolute != 0 && (absolute >= 1e15 || absolute < 1e-9)) {
    return value.toStringAsExponential(8).replaceFirst(RegExp(r'0+e'), 'e');
  }
  return value.toStringAsFixed(9).replaceFirst(RegExp(r'\.?0+$'), '');
}

String unitSymbol(String unit) => switch (unit) {
  'KB（十进制）' => 'KB',
  'MB（十进制）' => 'MB',
  'GB（十进制）' => 'GB',
  'TB（十进制）' => 'TB',
  'KiB（二进制）' => 'KiB',
  'MiB（二进制）' => 'MiB',
  'GiB（二进制）' => 'GiB',
  'TiB（二进制）' => 'TiB',
  _ => unit,
};
