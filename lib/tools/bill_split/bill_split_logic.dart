/// 计算包含额外费用后的每人应付金额。
double? splitBill({
  required double total,
  required int people,
  double extraFee = 0,
}) {
  if (!total.isFinite ||
      !extraFee.isFinite ||
      total < 0 ||
      extraFee < 0 ||
      people < 1 ||
      people > 10000) {
    return null;
  }
  final result = (total + extraFee) / people;
  return result.isFinite ? result : null;
}
