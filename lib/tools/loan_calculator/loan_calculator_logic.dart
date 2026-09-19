import 'dart:math' as math;

const maxLoanInputLength = 32;
const maxLoanPrincipal = 1e12;
const maxAnnualRate = 100.0;
const maxLoanMonths = 600;

class LoanPayment {
  const LoanPayment({
    required this.period,
    required this.payment,
    required this.principal,
    required this.interest,
    required this.balance,
  });

  final int period;
  final double payment;
  final double principal;
  final double interest;
  final double balance;
}

class LoanResult {
  const LoanResult({
    required this.monthlyPayment,
    required this.totalPayment,
    required this.totalInterest,
    required this.schedule,
  });

  final double monthlyPayment;
  final double totalPayment;
  final double totalInterest;
  final List<LoanPayment> schedule;
}

/// 仅计算固定年利率、按月等额本息；不读取网络利率或推断真实贷款条款。
LoanResult calculateLoan({
  required String principalText,
  required String annualRateText,
  required String monthsText,
}) {
  final principal = _boundedDouble(
    principalText,
    label: '贷款本金',
    minimum: 0,
    maximum: maxLoanPrincipal,
    strictlyGreaterThanMinimum: true,
  );
  final annualRate = _boundedDouble(
    annualRateText,
    label: '年利率',
    minimum: 0,
    maximum: maxAnnualRate,
  );
  if (monthsText.length > maxLoanInputLength ||
      !RegExp(r'^[0-9]+$').hasMatch(monthsText.trim())) {
    throw const FormatException('期数必须为 1–600 的整数月');
  }
  final months = int.tryParse(monthsText.trim());
  if (months == null || months < 1 || months > maxLoanMonths) {
    throw const FormatException('期数必须为 1–600 的整数月');
  }

  final monthlyRate = annualRate / 1200;
  final payment = monthlyRate == 0
      ? principal / months
      : principal *
            monthlyRate /
            (1 - math.pow(1 + monthlyRate, -months).toDouble());
  if (!payment.isFinite || payment <= 0) {
    throw const FormatException('当前数值无法可靠计算');
  }

  var balance = principal;
  var totalPayment = 0.0;
  var totalInterest = 0.0;
  final schedule = <LoanPayment>[];
  for (var period = 1; period <= months; period++) {
    final interest = balance * monthlyRate;
    final scheduledPrincipal = payment - interest;
    // 极端利率和期数组合可能让本金部分小于 double 精度，形成余额永不下降的伪计划。
    if (!scheduledPrincipal.isFinite ||
        scheduledPrincipal <= 0 ||
        balance - scheduledPrincipal == balance) {
      throw const FormatException('利率与期数组合超出可靠计算范围');
    }
    // 最后一期吸收浮点余量，避免显示接近零但未归零的剩余本金。
    final principalPart = period == months
        ? balance
        : math.min(scheduledPrincipal, balance);
    final actualPayment = principalPart + interest;
    balance = math.max(0, balance - principalPart);
    totalPayment += actualPayment;
    totalInterest += interest;
    schedule.add(
      LoanPayment(
        period: period,
        payment: actualPayment,
        principal: principalPart,
        interest: interest,
        balance: balance,
      ),
    );
  }
  if (![
        totalPayment,
        totalInterest,
        balance,
      ].every((value) => value.isFinite) ||
      balance != 0) {
    throw const FormatException('结果超出可表示范围');
  }
  return LoanResult(
    monthlyPayment: payment,
    totalPayment: totalPayment,
    totalInterest: totalInterest,
    schedule: List.unmodifiable(schedule),
  );
}

double _boundedDouble(
  String text, {
  required String label,
  required double minimum,
  required double maximum,
  bool strictlyGreaterThanMinimum = false,
}) {
  if (text.length > maxLoanInputLength) {
    throw FormatException('$label 不能超过 $maxLoanInputLength 个字符');
  }
  final value = double.tryParse(text.trim());
  final minimumInvalid =
      value != null &&
      (strictlyGreaterThanMinimum ? value <= minimum : value < minimum);
  if (value == null || !value.isFinite || minimumInvalid || value > maximum) {
    final relation = strictlyGreaterThanMinimum ? '大于' : '不小于';
    throw FormatException('$label 必须为$relation $minimum 且不超过 $maximum 的有限数字');
  }
  return value;
}

String formatLoanAmount(double value) => value.toStringAsFixed(2);
