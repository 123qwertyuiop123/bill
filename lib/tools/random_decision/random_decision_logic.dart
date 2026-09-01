import 'dart:math';

/// 使用安全随机源生成闭区间整数，避免上限溢出和超大范围分配。
int? secureRandomInt(int min, int max, {Random? random}) {
  if (min > max || max - min > 1000000000) return null;
  final source = random ?? Random.secure();
  return min + source.nextInt(max - min + 1);
}

String? chooseRandom(List<String> options, {Random? random}) {
  final safe = options
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .take(1000)
      .toList();
  if (safe.isEmpty) return null;
  final source = random ?? Random.secure();
  return safe[source.nextInt(safe.length)];
}
