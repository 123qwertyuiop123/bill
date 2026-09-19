import 'dart:math' as math;

const maxEquationInputLength = 32;
const maxEquationCoefficient = 1e100;

class EquationResult {
  const EquationResult({required this.kind, required this.values});
  final String kind;
  final Map<String, String> values;
}

/// 固定结构的数值求解器，不解析或执行用户表达式。
EquationResult solveQuadratic(String aText, String bText, String cText) {
  final originals = [
    _coefficient(aText, 'a'),
    _coefficient(bText, 'b'),
    _coefficient(cText, 'c'),
  ];
  final scale = originals.map((v) => v.abs()).reduce(math.max);
  if (scale == 0) {
    return const EquationResult(kind: '恒等式', values: {'说明': '任意 x 都满足方程'});
  }
  // 缩放使判别式的乘法保持在合理量级；不能把下溢系数静默当成零。
  final normalized = originals.map((v) => v / scale).toList();
  for (var i = 0; i < 3; i++) {
    if (originals[i] != 0 && normalized[i] == 0) {
      throw const FormatException('系数数量级差异过大，无法可靠计算');
    }
  }
  final a = normalized[0], b = normalized[1], c = normalized[2];
  if (a == 0) {
    if (b == 0) {
      return const EquationResult(kind: '无解', values: {'说明': '常数项不为 0'});
    }
    final root = -c / b;
    _finite(root);
    return EquationResult(
      kind: '一次方程',
      values: {'x': formatEquationNumber(root)},
    );
  }
  final square = b * b;
  final product = 4 * a * c;
  // 极小非零乘积下溢时，不能误报“两个相同实根”。
  if ((b != 0 && square == 0) || (a != 0 && c != 0 && product == 0)) {
    throw const FormatException('系数数量级差异过大，无法可靠计算判别式');
  }
  final delta = square - product;
  final originalDelta =
      originals[1] * originals[1] - 4 * originals[0] * originals[2];
  final deltaLabel = originalDelta == 0 && delta != 0
      ? '${formatEquationNumber(delta)}（系数归一化后）'
      : formatEquationNumber(originalDelta);
  final values = <String, String>{'判别式 Δ': deltaLabel};
  if (delta < 0) {
    final real = -b / (2 * a);
    final imaginary = math.sqrt(-delta) / (2 * a.abs());
    _finite(real);
    _finite(imaginary);
    values['x₁'] =
        '${formatEquationNumber(real)} + ${formatEquationNumber(imaginary)}i';
    values['x₂'] =
        '${formatEquationNumber(real)} − ${formatEquationNumber(imaginary)}i';
    return EquationResult(kind: '两个共轭复根', values: values);
  }
  if (delta == 0) {
    final root = -b / (2 * a);
    _finite(root);
    values['x₁ = x₂'] = formatEquationNumber(root);
    return EquationResult(kind: '两个相同实根', values: values);
  }
  // 避免 -b 与 sqrt(Δ) 接近时相减消去有效位，用根的乘积求另一个根。
  final q = -0.5 * (b + (b >= 0 ? 1 : -1) * math.sqrt(delta));
  final first = q / a;
  final second = c == 0 ? 0.0 : c / q;
  _finite(first);
  _finite(second);
  if (c != 0 && second == 0) {
    throw const FormatException('根超出可表示范围');
  }
  final roots = [first, second]..sort();
  values['x₁'] = formatEquationNumber(roots[0]);
  values['x₂'] = formatEquationNumber(roots[1]);
  return EquationResult(kind: '两个不同实根', values: values);
}

double _coefficient(String text, String label) {
  if (text.length > maxEquationInputLength) {
    throw FormatException('系数 $label 不能超过 32 个字符');
  }
  final value = double.tryParse(text.trim());
  if (value == null ||
      !value.isFinite ||
      value.abs() > maxEquationCoefficient) {
    throw FormatException('系数 $label 必须为绝对值不超过 1e100 的有限数');
  }
  return value;
}

void _finite(double value) {
  if (!value.isFinite) throw const FormatException('根超出可表示范围');
}

String formatEquationNumber(double value) {
  if (value == 0) return '0';
  if (value.abs() >= 1e12 || value.abs() < 1e-6) {
    return value.toStringAsExponential(8);
  }
  return value
      .toStringAsFixed(8)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
