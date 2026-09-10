const maxRomanInputLength = 32;

enum RomanConversionMode { numberToRoman, romanToNumber }

class RomanConversionResult {
  const RomanConversionResult({
    required this.input,
    required this.output,
    required this.explanation,
  });

  final String input;
  final String output;
  final String explanation;
}

const _romanValues = <(int, String)>[
  (1000, 'M'),
  (900, 'CM'),
  (500, 'D'),
  (400, 'CD'),
  (100, 'C'),
  (90, 'XC'),
  (50, 'L'),
  (40, 'XL'),
  (10, 'X'),
  (9, 'IX'),
  (5, 'V'),
  (4, 'IV'),
  (1, 'I'),
];

final _canonicalRoman = RegExp(
  r'^M{0,3}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$',
);

/// 转换常用规范范围内的十进制整数，避免引入不统一的加横线扩展记法。
String integerToRoman(int value) {
  if (value < 1 || value > 3999) {
    throw const FormatException('十进制整数必须在 1–3999 范围内');
  }
  var remaining = value;
  final output = StringBuffer();
  for (final (number, symbol) in _romanValues) {
    while (remaining >= number) {
      output.write(symbol);
      remaining -= number;
    }
  }
  return output.toString();
}

/// 严格接受规范罗马数字；例如 IIII、VX 不会被静默纠正。
int romanToInteger(String input) {
  final roman = input.trim().toUpperCase();
  if (roman.isEmpty) throw const FormatException('请输入罗马数字');
  if (roman.length > maxRomanInputLength) {
    throw const FormatException('罗马数字不能超过 32 个字符');
  }
  if (!_canonicalRoman.hasMatch(roman)) {
    throw const FormatException('请输入 1–3999 范围内的规范罗马数字');
  }
  var total = 0;
  var index = 0;
  for (final (number, symbol) in _romanValues) {
    while (roman.startsWith(symbol, index)) {
      total += number;
      index += symbol.length;
    }
  }
  if (index != roman.length || integerToRoman(total) != roman) {
    throw const FormatException('罗马数字格式不规范');
  }
  return total;
}

RomanConversionResult convertRoman(String input, RomanConversionMode mode) {
  if (input.length > maxRomanInputLength) {
    throw const FormatException('输入不能超过 32 个字符');
  }
  switch (mode) {
    case RomanConversionMode.numberToRoman:
      final normalized = input.trim();
      if (normalized.isEmpty) throw const FormatException('请输入十进制整数');
      if (!RegExp(r'^[0-9]+$').hasMatch(normalized)) {
        throw const FormatException('请输入不含小数或符号的十进制整数');
      }
      final value = int.tryParse(normalized);
      if (value == null) throw const FormatException('十进制整数超出支持范围');
      return RomanConversionResult(
        input: normalized,
        output: integerToRoman(value),
        explanation: '使用规范罗马数字表示',
      );
    case RomanConversionMode.romanToNumber:
      final normalized = input.trim().toUpperCase();
      return RomanConversionResult(
        input: normalized,
        output: romanToInteger(normalized).toString(),
        explanation: '对应的十进制整数',
      );
  }
}
