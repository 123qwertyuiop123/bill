import 'dart:math' as math;

const maxStatisticsInputLength = 100000;
const maxStatisticsValueCount = 10000;
const maxStatisticsAbsoluteValue = 1e100;

class StatisticsResult {
  const StatisticsResult({
    required this.count,
    required this.sum,
    required this.mean,
    required this.median,
    required this.minimum,
    required this.maximum,
    required this.range,
    required this.populationStandardDeviation,
    required this.sampleStandardDeviation,
  });

  final int count;
  final double sum;
  final double mean;
  final double median;
  final double minimum;
  final double maximum;
  final double range;
  final double populationStandardDeviation;
  final double? sampleStandardDeviation;
}

/// 解析由英文逗号或空白分隔的有限数字，并计算基础描述统计。
StatisticsResult calculateStatistics(String input) {
  if (input.isEmpty) throw const FormatException('请输入数字列表');
  if (input.length > maxStatisticsInputLength) {
    throw const FormatException('输入内容不能超过 100000 个字符');
  }
  final trimmed = input.trim();
  if (trimmed.isEmpty) throw const FormatException('请输入数字列表');
  final tokens = trimmed.split(RegExp(r'[\s,]+'));
  if (tokens.length > maxStatisticsValueCount) {
    throw const FormatException('数字数量不能超过 10000 个');
  }

  final values = <double>[];
  for (var index = 0; index < tokens.length; index++) {
    final token = tokens[index];
    final value = double.tryParse(token);
    if (value == null ||
        !value.isFinite ||
        value.abs() > maxStatisticsAbsoluteValue) {
      // 错误信息只指出位置，不回显可能包含敏感内容或超长文本的原始输入。
      throw FormatException('第 ${index + 1} 项不是支持范围内的有限数字');
    }
    values.add(value);
  }

  // Kahan 求和降低大量大小不同数值相加时的舍入误差。
  var sum = 0.0;
  var compensation = 0.0;
  var mean = 0.0;
  var m2 = 0.0;
  for (var index = 0; index < values.length; index++) {
    final value = values[index];
    final adjusted = value - compensation;
    final nextSum = sum + adjusted;
    compensation = (nextSum - sum) - adjusted;
    sum = nextSum;

    // Welford 在线算法避免先平方后相减导致的灾难性消差。
    final count = index + 1;
    final delta = value - mean;
    mean += delta / count;
    final delta2 = value - mean;
    m2 += delta * delta2;
  }
  if (!sum.isFinite || !mean.isFinite || !m2.isFinite) {
    throw const FormatException('统计结果超出支持范围');
  }

  final sorted = List<double>.from(values)..sort();
  final middle = sorted.length ~/ 2;
  final median = sorted.length.isOdd
      ? sorted[middle]
      : sorted[middle - 1] / 2 + sorted[middle] / 2;
  final populationVariance = math.max(0.0, m2 / values.length);
  final sampleVariance = values.length < 2
      ? null
      : math.max(0.0, m2 / (values.length - 1));
  return StatisticsResult(
    count: values.length,
    sum: sum,
    mean: mean,
    median: median,
    minimum: sorted.first,
    maximum: sorted.last,
    range: sorted.last - sorted.first,
    populationStandardDeviation: math.sqrt(populationVariance),
    sampleStandardDeviation: sampleVariance == null
        ? null
        : math.sqrt(sampleVariance),
  );
}

String formatStatisticNumber(double value) {
  final absolute = value.abs();
  if (absolute >= 1e12 || (absolute > 0 && absolute < 1e-6)) {
    return value.toStringAsExponential(6);
  }
  return value
      .toStringAsFixed(6)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
