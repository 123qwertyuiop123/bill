import 'dart:math' as math;

/// 色环名称与数值映射仅用于解码标识，不代表元件的实测值。
enum ResistorColor {
  black('黑色', 0, 0xff252525),
  brown('棕色', 1, 0xff805030),
  red('红色', 2, 0xffc63838),
  orange('橙色', 3, 0xffdf8434),
  yellow('黄色', 4, 0xffd8bd39),
  green('绿色', 5, 0xff36804e),
  blue('蓝色', 6, 0xff3574aa),
  violet('紫色', 7, 0xff87599d),
  gray('灰色', 8, 0xff888888),
  white('白色', 9, 0xffeeeeee),
  gold('金色', -1, 0xffbd9c3a),
  silver('银色', -2, 0xffb4b4b4);

  const ResistorColor(this.label, this.exponent, this.argb);
  final String label;
  final int exponent;
  final int argb;

  double? get tolerance => switch (this) {
    brown => 1,
    red => 2,
    green => 0.5,
    blue => 0.25,
    violet => 0.1,
    gray => 0.05,
    gold => 5,
    silver => 10,
    _ => null,
  };
}

class ResistorResult {
  const ResistorResult(this.ohms, {this.tolerancePercent});
  final double ohms;
  final double? tolerancePercent;
  double? get minimum =>
      tolerancePercent == null ? null : ohms * (1 - tolerancePercent! / 100);
  double? get maximum =>
      tolerancePercent == null ? null : ohms * (1 + tolerancePercent! / 100);
}

/// 校验每个环的位置合法性，不能把金/银色误当有效数字。
ResistorResult decodeResistorBands(List<ResistorColor> bands) {
  if (bands.length != 4 && bands.length != 5) {
    throw const FormatException('仅支持 4 环或 5 环电阻');
  }
  final digitCount = bands.length - 2;
  var significant = 0;
  for (var index = 0; index < digitCount; index++) {
    final digit = bands[index].exponent;
    if (digit < 0 || digit > 9 || (index == 0 && digit == 0)) {
      throw const FormatException('有效数字色环不合法，第 1 环不能为黑色');
    }
    significant = significant * 10 + digit;
  }
  final tolerance = bands.last.tolerance;
  if (tolerance == null) throw const FormatException('误差色环不合法');
  final multiplier = math.pow(10, bands[digitCount].exponent).toDouble();
  return ResistorResult(significant * multiplier, tolerancePercent: tolerance);
}

/// 第一版仅接受三/四位 ASCII 数字编码，不推断未标注的元件误差。
ResistorResult decodeSmdResistor(String input) {
  if (!RegExp(r'^(?:[0-9]{3}|[0-9]{4})$').hasMatch(input)) {
    throw const FormatException('请输入完整的 3 位或 4 位数字贴片编码');
  }
  final significant = int.parse(input.substring(0, input.length - 1));
  final exponent = int.parse(input.substring(input.length - 1));
  return ResistorResult(significant * math.pow(10, exponent).toDouble());
}

String formatResistance(double ohms) {
  final (value, unit) = ohms >= 1e9
      ? (ohms / 1e9, 'GΩ')
      : ohms >= 1e6
      ? (ohms / 1e6, 'MΩ')
      : ohms >= 1e3
      ? (ohms / 1e3, 'kΩ')
      : (ohms, 'Ω');
  final number = value
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return '$number $unit';
}
