/// 求 [part] 占 [total] 的百分比。总数为零或输入无效时返回 null。
double? percentageOf(double part, double total) {
  if (!part.isFinite || !total.isFinite || total == 0) return null;
  return part / total * 100;
}

/// 将 [value] 按 [percent] 百分比增加；负数百分比表示减少。
double? applyPercentageChange(double value, double percent) {
  if (!value.isFinite || !percent.isFinite || percent.abs() > 100000) {
    return null;
  }
  final result = value * (1 + percent / 100);
  return result.isFinite ? result : null;
}

/// 按中国常用“几折”表示法计算折后价，例如 8.5 折等于原价的 85%。
double? discountedPrice(double price, double discount) {
  if (!price.isFinite ||
      !discount.isFinite ||
      price < 0 ||
      discount < 0 ||
      discount > 10) {
    return null;
  }
  return price * discount / 10;
}

String formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
