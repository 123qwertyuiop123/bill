enum LuhnMode { validate, generate }

class LuhnResult {
  const LuhnResult({
    required this.valid,
    required this.digit,
    required this.sequence,
  });
  final bool valid;
  final String digit;
  final String sequence;
}

/// 仅校验数学规则，绝不意味着号码真实存在；字符串运算保留前导零。
LuhnResult processLuhn(String input, LuhnMode mode) {
  final min = mode == LuhnMode.validate ? 2 : 1;
  final max = mode == LuhnMode.validate ? 128 : 127;
  if (input.length < min || input.length > max) {
    throw FormatException('请输入 $min–$max 位数字');
  }
  // 不清洗或截断非法字符，防止悄悄改变被校验的序列。
  if (input.codeUnits.any((c) => c < 48 || c > 57)) {
    throw const FormatException('数字序列只能包含 0–9');
  }
  final body = mode == LuhnMode.generate
      ? input
      : input.substring(0, input.length - 1);
  var sum = 0;
  var doubleDigit = true;
  for (var i = body.length - 1; i >= 0; i--) {
    var value = body.codeUnitAt(i) - 48;
    if (doubleDigit) {
      value *= 2;
      if (value > 9) value -= 9;
    }
    sum += value;
    doubleDigit = !doubleDigit;
  }
  final digit = '${(10 - sum % 10) % 10}';
  return LuhnResult(
    valid: mode == LuhnMode.generate || input.endsWith(digit),
    digit: digit,
    sequence: mode == LuhnMode.generate ? '$body$digit' : input,
  );
}
