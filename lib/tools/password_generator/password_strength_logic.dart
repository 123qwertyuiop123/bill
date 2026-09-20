import 'dart:math' as math;

const maxPasswordEvaluationLength = 256;

enum PasswordStrengthLevel { veryWeak, weak, medium, strong, veryStrong }

extension PasswordStrengthLevelLabel on PasswordStrengthLevel {
  String get label => switch (this) {
    PasswordStrengthLevel.veryWeak => '很弱',
    PasswordStrengthLevel.weak => '较弱',
    PasswordStrengthLevel.medium => '一般',
    PasswordStrengthLevel.strong => '较强',
    PasswordStrengthLevel.veryStrong => '很强',
  };
}

class PasswordStrengthResult {
  const PasswordStrengthResult({
    required this.level,
    required this.score,
    required this.estimatedBits,
    this.warning,
    this.suggestions = const [],
    this.error,
  });

  const PasswordStrengthResult.error(String message)
    : level = PasswordStrengthLevel.veryWeak,
      score = 0,
      estimatedBits = 0,
      warning = null,
      suggestions = const [],
      error = message;

  final PasswordStrengthLevel level;
  final int score;
  final double estimatedBits;
  final String? warning;
  final List<String> suggestions;
  final String? error;

  bool get isSuccess => error == null;
}

const _commonPatterns = <String>[
  'password',
  'passw0rd',
  'qwerty',
  'admin',
  'letmein',
  'welcome',
  'iloveyou',
  '123456',
  '111111',
  'abc123',
  '密码',
];

const _orderedSources = <String>[
  '0123456789',
  'abcdefghijklmnopqrstuvwxyz',
  'qwertyuiopasdfghjklzxcvbnm',
];

/// 对密码进行有界、保守的本地评估。
///
/// 该结果只用于帮助用户发现明显弱模式，不查询泄露库，也不承诺真实破解时间。
/// 返回值不保存原始密码，避免敏感内容在页面状态之外传播。
PasswordStrengthResult evaluatePasswordStrength(String password) {
  if (password.isEmpty) {
    return const PasswordStrengthResult.error('请输入待检查的密码');
  }
  if (password.length > maxPasswordEvaluationLength) {
    return const PasswordStrengthResult.error('密码最多 256 个字符');
  }

  final lower = password.toLowerCase();
  final hasLower = RegExp(r'[a-z]').hasMatch(password);
  final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
  final hasDigit = RegExp(r'[0-9]').hasMatch(password);
  final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  final classCount = [
    hasLower,
    hasUpper,
    hasDigit,
    hasSymbol,
  ].where((value) => value).length;

  var poolSize = 0;
  if (hasLower) poolSize += 26;
  if (hasUpper) poolSize += 26;
  if (hasDigit) poolSize += 10;
  if (hasSymbol) poolSize += 32;
  poolSize = math.max(poolSize, 1);

  var bits = password.runes.length * math.log(poolSize) / math.ln2;
  final containsCommon = _commonPatterns.any(lower.contains);
  final repeated = _isRepeatedPattern(password);
  final sequential = _containsOrderedRun(lower);

  if (classCount == 1) bits *= 0.65;
  if (password.runes.length < 8) bits = math.min(bits, 15);
  if (containsCommon) bits = math.min(bits, 24);
  if (repeated) bits = math.min(bits, 18);
  if (sequential) bits -= 14;
  bits = bits.clamp(0, 120).toDouble();

  final score = switch (bits) {
    < 20 => 0,
    < 35 => 1,
    < 55 => 2,
    < 75 => 3,
    _ => 4,
  };
  final suggestions = <String>[
    if (password.runes.length < 12) '建议使用至少 12 个字符',
    if (classCount < 3) '混合大小写字母、数字或符号',
    if (containsCommon) '避免常见单词、姓名和简单数字组合',
    if (repeated) '避免重复同一字符或短片段',
    if (sequential) '避免键盘、字母或数字连续序列',
  ];
  if (suggestions.isEmpty && score < 4) {
    suggestions.add('增加长度通常比简单替换字符更有效');
  }

  return PasswordStrengthResult(
    level: PasswordStrengthLevel.values[score],
    score: score,
    estimatedBits: bits,
    warning: containsCommon
        ? '检测到常见密码模式，评分已降低'
        : repeated
        ? '检测到重复模式，容易被猜测'
        : sequential
        ? '检测到连续字符，评分已降低'
        : null,
    suggestions: suggestions,
  );
}

bool _isRepeatedPattern(String value) {
  if (value.length < 3) return false;
  for (var size = 1; size <= math.min(4, value.length ~/ 2); size++) {
    if (value.length % size != 0) continue;
    final part = value.substring(0, size);
    if (List.filled(value.length ~/ size, part).join() == value) return true;
  }
  return false;
}

bool _containsOrderedRun(String value) {
  if (value.length < 4) return false;
  for (final source in _orderedSources) {
    final reversed = source.split('').reversed.join();
    for (var index = 0; index <= source.length - 4; index++) {
      if (value.contains(source.substring(index, index + 4)) ||
          value.contains(reversed.substring(index, index + 4))) {
        return true;
      }
    }
  }
  return false;
}
